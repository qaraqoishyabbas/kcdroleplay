local p=game.Players.LocalPlayer
local flight=assert(p.PlayerScripts:FindFirstChild('ExplorerFlight'),'ExplorerFlight missing')
assert(flight:GetAttribute('Ready')==true,'Flight controller did not start')
assert(flight:GetAttribute('NoclipEnabled')==false,'Flight must be off at spawn')
assert(flight:GetAttribute('FlightSpeed')==80,'Unexpected initial flight speed')
assert(p.Character.HumanoidRootPart.Anchored==false,'Character must remain unanchored')
print('NOCLIP_READY_PASS')
