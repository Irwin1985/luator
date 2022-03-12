------------------------------------------------------------
-- TokenType
------------------------------------------------------------
local TokenType = {  
	number  = 'NUMBER',
	plus    = 'PLUS',
	minus   = 'MINUS',
	mul     = 'MUL',
	div     = 'DIV',
	lparen  = 'LPAREN',
	rparen  = 'RPAREN',
	illegal = 'ILLEGAL',
	eof     = 'EOF'
}

local Token = {
	type 	= '',
	literal = ''
}

------------------------------------------------------------
-- Constructor para el Token
------------------------------------------------------------
function Token:new (type, literal)
	local t = {}
	setmetatable(t, self)
	self.__index 	= self
	t.type    		= type
	t.literal 		= literal
	return t
end

function Token:print()  
	print("Token(" .. self.type ..",'" .. self.literal .."')")
end

------------------------------------------------------------
-- Lexer
------------------------------------------------------------
local Lexer = {
	text = '',
	pos = 0,
	ch = 0
}

function Lexer:new(text)
	local l = {}
	setmetatable(l, self)
	self.__index = self

	l.text = text
	l.pos = 1
	l.ch = string.sub(l.text, l.pos, 1) -- prime the first character
	return l
end

function Lexer:advance()
	self.pos = self.pos + 1
	if self.pos > #self.text then
		self.ch = 0
	else
		self.ch = string.sub(self.text, self.pos, self.pos)
	end
end

function Lexer:skipWhitespace() 
	while not self:isAtEnd() and self:isSpace(self.ch) do
		self:advance()
	end
end

function Lexer:readNumber() 
	local pos, lexeme = self.pos, ''
	while not self:isAtEnd() and self:isDigit(self.ch) do
		lexeme = lexeme .. self.ch
		self:advance()
	end
	local endpos = self.pos-1
	return string.sub(self.text, pos, endpos)
end

function Lexer:nextToken()
	::continue::
	while not self:isAtEnd() do
		if self:isSpace(self.ch) then
			self:skipWhitespace()
			goto continue
		end
		if self:isDigit(self.ch) then
			return Token:new(TokenType.number, self:readNumber())
		end

		if self.ch == '(' then
			self:advance()
			return Token:new(TokenType.lparen, '(')
		end

		if self.ch == ')' then
			self:advance()
			return Token:new(TokenType.rparen, ')')
		end

		if self.ch == '+' then
			self:advance()
			return Token:new(TokenType.plus, '+')
		end

		if self.ch == '-' then
			self:advance()
			return Token:new(TokenType.minus, '-')
		end

		if self.ch == '*' then
			self:advance()
			return Token:new(TokenType.mul, '*')
		end

		if self.ch == '/' then
			self:advance()
			return Token:new(TokenType.div, '/')
		end
		local ch = self.ch
		self:advance()
		return Token:new(TokenType.illegal, ch)
	end
	return Token:new(TokenType.eof, '')
end

function Lexer:isAtEnd()
	return self.ch == 0
end

function Lexer:isSpace(ch)
	return string.byte(ch) == 32
end

function Lexer:isDigit(ch)
	return string.byte('0') <= string.byte(ch) and string.byte(ch) <= string.byte('9')
end

------------------------------------------------------------
-- Parser
------------------------------------------------------------
local Parser = {
	l 		 = nil, -- Lexer
	curToken = nil, -- Current Token
}

function Parser:new(lexer)
	local p = {}
	setmetatable(p, self)
	self.__index = self
	p.l = lexer
	p.curToken = p.l:nextToken() -- Prime the token

	return p
end

function Parser:eat(type)
	if self.curToken.type == type then
		self.curToken = self.l:nextToken()
	else
		error("Unexpected token " .. self.curToken.type .. ", expected: " .. type)
	end
end

-- expression ::= term (('+' | '-') term)*
function Parser:expression()
	local node = self:term()
	while self.curToken.type == TokenType.plus or self.curToken.type == TokenType.minus do
		local token = self.curToken
		self:eat(token.type)
		node = {
			type  = 'BinOp',
			left  = node,
			op    = token,
			right = self:term()
		}
	end
	return node
end

-- term ::= factor (('*' | '/') factor)*
function Parser:term()
	local node = self:factor()
	while self.curToken.type == TokenType.mul or self.curToken.type == TokenType.div do
		local token = self.curToken
		self:eat(token.type)
		node = {
			type  = 'BinOp',
			left  = node,
			op    = token,
			right = self:factor()
		}
	end
	return node
end

-- factor ::= number | '(' expression ')'
function Parser:factor()
	if self.curToken.type == TokenType.plus or self.curToken.type == TokenType.minus then
		local token = self.curToken
		self:eat(token.type)
		return {
			type 	= 'Unary',
			op 		= token,
			right 	= self:factor()
		}
	elseif self.curToken.type == TokenType.lparen then
		self:eat(TokenType.lparen)
		local node = self:expression()
		self:eat(TokenType.rparen)
		return node
	else -- number
		local node = {
			type = 'Num',
			value = tonumber(self.curToken.literal)
		} 
		self:eat(TokenType.number)
		return node
	end  
end

function Parser:parse()
	return self:expression()
end
------------------------------------------------------------
-- Interpreter
------------------------------------------------------------
local Interpreter = {
	p = nil -- The Parser
}

function Interpreter:new(parser)
	local i = {}
	setmetatable(i, self)
	self.__index = self
	i.p = parser

	return i
end

function Interpreter:visit(node)
	if node.type == 'BinOp' then
		return self:visitBinOp(node)
	elseif node.type == 'Unary' then
		return self:visitUnary(node)
	else
		return self:visitNum(node)
	end
end

function Interpreter:visitBinOp(node)
	local operator = node.op.type
	if operator == TokenType.plus then
		return self:visit(node.left) + self:visit(node.right)
	elseif operator == TokenType.minus then
		return self:visit(node.left) - self:visit(node.right)
	elseif operator == TokenType.mul then
		return self:visit(node.left) * self:visit(node.right)
	elseif operator == TokenType.div then
		local left, right = self:visit(node.left), self:visit(node.right)
		if right == 0 then
			error("division by zero")
		else
			return left / right
		end
	end
end

function Interpreter:visitUnary(node)
	local right = self:visit(node.right)
	if node.op.type == TokenType.plus then
		return right
	else
		return right * -1
	end
end

function Interpreter:visitNum(node)
	return node.value
end

function Interpreter:interpret()
	local tree = self.p:parse()
	return self:visit(tree)
end

------------------------------------------------------------
-- Main
------------------------------------------------------------
function main()
	::continue::
	while true do
		io.write("calc> ")
		text = io.read()
		if #text == 0 then
			goto continue
		end
		local l = Lexer:new(text)
		local p = Parser:new(l)
		local i = Interpreter:new(p)
		local result = i:interpret()
		print(result)
	end
end

main() -- main caller