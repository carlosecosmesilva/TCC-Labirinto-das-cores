local sensor = script.Parent
local debounceFinal = false

sensor.Anchored = true
sensor.CanCollide = false
sensor.Transparency = 1

sensor.Touched:Connect(function(hit)
	local player = game.Players:GetPlayerFromCharacter(hit.Parent)

	if player and not debounceFinal then
		debounceFinal = true

		-- Calcula o tempo decorrido desde o Spawn
		local horaSpawn = player:GetAttribute("HoraSpawn") or os.clock()
		local tempoTotal = math.floor((os.clock() - horaSpawn) * 100) / 100

		-- Garante a gravação no NumberValue
		local tTotalObj = player:FindFirstChild("TempoTotalGeral")
		if tTotalObj then
			tTotalObj.Value = tempoTotal
		end

		-- Dispara o processamento do relatório pelo Chefe
		sensor:SetAttribute("ProcessarPlayer", player.Name)
		print("Chefe alcançado por " .. player.Name .. ". Tempo Total: " .. tempoTotal .. "s")
	end
end)