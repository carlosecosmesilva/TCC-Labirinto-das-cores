 local HttpService = game:GetService("HttpService")

game.Players.PlayerAdded:Connect(function(player)
	-- Variável para guardar o trajeto final formatado como JSON
	local trajetoStr = player:FindFirstChild("JSON_Trajeto")
	if not trajetoStr then
		trajetoStr = Instance.new("StringValue")
		trajetoStr.Name = "JSON_Trajeto"
		trajetoStr.Value = "[]"
		trajetoStr.Parent = player
	end

	player.CharacterAdded:Connect(function(character)
		local root = character:WaitForChild("HumanoidRootPart")
		local coordenadas = {}
		local tracking = true

		-- Thread paralela que grava a posição (X, Z) do jogador a cada 0.5 segundos
		task.spawn(function()
			while tracking and character and character.Parent and root and root.Parent do
				task.wait(0.5) -- Intervalo de captura (ajuste se quiser mais ou menos pontos)

				local pos = root.Position
				table.insert(coordenadas, {
					x = math.floor(pos.X * 10) / 10,
					z = math.floor(pos.Z * 10) / 10
				})

				-- Serializa e atualiza a string em tempo real
				trajetoStr.Value = HttpService:JSONEncode(coordenadas)
			end
		end)

		-- Interrompe o rastreamento se o personagem morrer
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			tracking = false
		end)
	end)
end)