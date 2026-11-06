
local Lexer = {}

Lexer.SYMBOLS = {" ", ";", "\"", "\\"}

export type LexemeKind = "WORD" | ";" | " " | "\"" | "\\"

export type Lexeme = {
	kind: LexemeKind,
	span: vector,
}

local function getSpan(position: number, str: string): vector
	return vector.create(position, position + #str - 1)
end

local function pushWord(lexemes: {Lexeme}, wordSequence: {string}, termPosition: number): ()
	if #wordSequence == 0 then
		return
	end

	local word = table.concat(wordSequence, "")

	table.insert(lexemes, {
		kind = "WORD",
		span = vector.create(termPosition - #word, termPosition - 1),
	})

	table.clear(wordSequence)
end

local function pushLexeme(lexemes: {Lexeme}, wordSequence: {string}, kind: LexemeKind, value: string, position: number): ()
	pushWord(lexemes, wordSequence, position)

	table.insert(lexemes, {
		kind = kind,
		span = getSpan(position, value),
	})
end

function Lexer.Lex(input: string): {Lexeme}
	local lexemes: {Lexeme} = {}

	local wordSequence: {string} = {}
	for i, v in utf8.codes(input) do
		local char = utf8.char(v)

		local ranOnce = false
		for _, symbol in Lexer.SYMBOLS do
			if symbol == char then
				pushLexeme(lexemes, wordSequence, symbol :: LexemeKind, symbol, i)

				ranOnce = true
				break
			end
		end

		if not ranOnce then
			table.insert(wordSequence, char)
		end
	end

	pushWord(lexemes, wordSequence, #input + 1)

	return lexemes
end

return table.freeze(Lexer)