local Lexer = require("./Lexer")

export type TokenKind = "COMMAND" | "ARGUMENT"

export type Token = {
	kind: TokenKind,
	span: vector,
	parsed_content: string,
}

export type Word = {
	span: vector,
	parsed_content: string,
}

local Parser = {}

local function pushToken(tokens: {Token}, kind: TokenKind, span: vector, parsed_content: string): ()
	table.insert(tokens, {
		kind = kind,
		span = span,
		parsed_content = parsed_content,
	})
end

local function pushWord(tokens: {Token}, wordSequence: {Word}, isArgument: boolean): ()
	if #wordSequence == 0 then
		return
	end

	local spanStart = wordSequence[1].span.x
	local spanStop = wordSequence[#wordSequence].span.y

	local parsed_content = ""
	for _, word in wordSequence do
		parsed_content ..= word.parsed_content
	end

	pushToken(tokens, if isArgument then "ARGUMENT" else "COMMAND", vector.create(spanStart, spanStop), parsed_content)

	table.clear(wordSequence)
end

function Parser.Parse(input: string, lexemes: {Lexer.Lexeme}): {ok: true, tokens: {Token}} | {ok: false, err: string, span: vector}
	local tokens: {Token} = {}

	local quoteSpan: vector?
	local isInQuote = false
	local isEscaped = false
	local isArgument = false

	local wordSequence: {Word} = {}

	for i, lexeme in lexemes do
		if not isEscaped then
			if lexeme.kind == "\\" then
				isEscaped = true
				continue
			elseif lexeme.kind == "\"" then
				if not isInQuote then
					if #wordSequence ~= 0 then
						return {
							ok = false,
							err = `Expected whitespace before quote ({lexeme.span.x}-{lexeme.span.y})`,
							span = lexeme.span,
						}
					end
				end

				isInQuote = not isInQuote

				if isInQuote then
					quoteSpan = lexeme.span
				else
					quoteSpan = nil
				end

				pushWord(tokens, wordSequence, isArgument)

				continue
			end
		end

		isEscaped = false

		if isInQuote or lexeme.kind == "WORD" then
			table.insert(wordSequence, {
				span = lexeme.span,
				parsed_content = string.sub(input, lexeme.span.x, lexeme.span.y)
			})
		elseif lexeme.kind == ";" then
			pushWord(tokens, wordSequence, isArgument)
			isArgument = false
		else
			local isZero = #wordSequence > 0
			pushWord(tokens, wordSequence, isArgument)
			if isZero then
				isArgument = true
			end
		end
	end

	pushWord(tokens, wordSequence, isArgument)

	if isInQuote and quoteSpan then
		return {
			ok = false,
			err = "Unterminated quote",
			span = quoteSpan,
		}
	end

	return {
		ok = true,
		tokens = tokens,
	}
end

return table.freeze(Parser)