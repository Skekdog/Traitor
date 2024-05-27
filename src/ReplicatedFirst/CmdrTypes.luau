export type CommandDefinition = {
    Name: string,
    Aliases: {string},
    Description: string,
    Group: "Admin" | "All",
    Args: {
        {
            Type: "string" | "number" | "integer" | "boolean" | "player" | "playerId" | "team" | "command" | "userInput" | "brickColor" | "teamColor" | "color3" | "hexColor3" | "brickColor3" | "vector3" | "vector2" | "duration" | "storedKey" | "url"
            | "strings" | "numbers" | "integers" | "booleans" | "players" | "playerIds" | "teams" | "teamPlayers" | "commands" | "userInputs" | "brickColors" | "teamColors" | "color3s" | "hexColor3s" | "brickColor3s" | "vector3s" | "vector2s" | "durations" | "storedKeys" | "urls",
            Name: string,
            Description: string,
        }
    }
}

type context = {
    GetData: (self: context) -> any,
    [any]: any,
}
export type CommandFunction = (context: context, any) -> string

return {}