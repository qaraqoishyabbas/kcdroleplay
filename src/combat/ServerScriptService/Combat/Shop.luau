-- Weapon seller: a fixed catalog with prices, gold is a player attribute.
local Shop = {}
local ctx = nil

function Shop.init(context)
	ctx = context
end

function Shop.catalog()
	return ctx.config.Shop
end

function Shop.entry(itemId)
	for _, item in ctx.config.Shop do
		if item.Id == itemId then
			return item
		end
	end
	return nil
end

function Shop.displayName(itemId)
	for _, weapon in ctx.config.Weapons do
		if weapon.Id == itemId then
			return weapon.Name
		end
	end
	for _, piece in ctx.config.Armor do
		if piece.Id == itemId then
			return piece.Name
		end
	end
	return itemId
end

function Shop.open(player)
	ctx.net.Shop:FireClient(player, {
		open = true,
		gold = ctx.stats.getGold(player),
	})
end

function Shop.close(player)
	ctx.net.Shop:FireClient(player, { open = false, gold = ctx.stats.getGold(player) })
end

function Shop.buy(player, itemId)
	if type(itemId) ~= "string" then
		return
	end
	local item = Shop.entry(itemId)
	if not item then
		ctx.net.Notice:FireClient(player, { text = "Такого товара нет", kind = "bad" })
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		ctx.net.Notice:FireClient(player, { text = "Сначала вернись в бой", kind = "bad" })
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local vendor = ctx.world.vendorPoint
	if not root or not vendor or not vendor.Parent or (root.Position-vendor.Position).Magnitude > 14 then
		ctx.net.Notice:FireClient(player, { text = "Подойди к оружейнику", kind = "bad" })
		return
	end
	local gold = ctx.stats.getGold(player)
	if gold < item.Price then
		ctx.net.Notice:FireClient(player, { text = "Не хватает " .. (item.Price - gold) .. " золота", kind = "bad" })
		return
	end
	local ok = false
	if item.Kind == "Weapon" then
		ok = ctx.arsenal.setWeapon(player, item.Id)
	elseif item.Kind == "Shield" then
		ok = ctx.arsenal.setShield(player, true)
	elseif item.Kind == "Armor" then
		ok = ctx.arsenal.wear(player, item.Id)
	end
	if not ok then
		ctx.net.Notice:FireClient(player, { text = "Не удалось выдать предмет", kind = "bad" })
		return
	end
	ctx.stats.setGold(player, gold - item.Price)
	ctx.net.Notice:FireClient(player, { text = "Куплено: " .. Shop.displayName(item.Id) .. " за " .. item.Price, kind = "good" })
	ctx.net.Hud:FireClient(player, ctx.stats.hudFor(player))
	ctx.net.Shop:FireClient(player, { open = true, gold = ctx.stats.getGold(player) })
end

return Shop
