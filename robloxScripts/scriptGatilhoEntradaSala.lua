local gatilho = script.Parent
gatilho.Anchored = true
gatilho.CanCollide = false
gatilho.Transparency = 1

gatilho.Touched:Connect(function(hit)
	local player = game.Players:GetPlayerFromCharacter(hit.Parent)
	if player then
		-- Guarda o instante exato que o jogador pisou na entrada da sala
		player.TempoEntradaSalaAtual.Value = os.clock()
	end
end)