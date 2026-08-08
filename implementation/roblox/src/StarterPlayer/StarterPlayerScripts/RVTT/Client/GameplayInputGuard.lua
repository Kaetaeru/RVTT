--!strict

local Guard = {}

function Guard.allows(processed: boolean, focusedTextBox: TextBox?): boolean
	return not processed and focusedTextBox == nil
end

return Guard
