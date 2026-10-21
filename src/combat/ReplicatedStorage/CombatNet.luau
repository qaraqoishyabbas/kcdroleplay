-- Remote plumbing for the combat system.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = {}
Net.FolderName = "CombatRemotes"
Net.Names = { "Attack", "Block", "DrawStart", "Release", "Hud", "Notice", "Shop", "Buy" }

function Net.server()
	local folder = ReplicatedStorage:FindFirstChild(Net.FolderName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = Net.FolderName
		folder.Parent = ReplicatedStorage
	end
	local remotes = {}
	for _, name in Net.Names do
		local remote = folder:FindFirstChild(name)
		if not remote then
			remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
		remotes[name] = remote
	end
	return remotes
end

function Net.client()
	local folder = ReplicatedStorage:WaitForChild(Net.FolderName, 60)
	assert(folder, "CombatRemotes не появились: серверный скрипт боя не запущен")
	local remotes = {}
	for _, name in Net.Names do
		remotes[name] = folder:WaitForChild(name, 30)
	end
	return remotes
end

return Net
