local labelMonitor = script.Parent
local modelo = labelMonitor.Parent.Parent.Parent
local gatilho = modelo:WaitForChild("GatilhoFinal")

local ProximityPromptService = game:GetService("ProximityPromptService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ClinicaDataStore = DataStoreService:GetDataStore("BancoDadosTCC_Fuzzy")

local CHAVE_MESTRA = "ListaPacientes" 

local prompt = gatilho:FindFirstChildOfClass("ProximityPrompt")
if not prompt then
	prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Exportar Banco (CSV)"
	prompt.ObjectText = "Painel de BI"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 1
	prompt.MaxActivationDistance = 15
	prompt.Enabled = false 
	game.Players.PlayerAdded:Connect(function(player)
		if player.UserId == game.CreatorId or player.Name == "c4marte" then
			prompt.Enabled = true 
		end
	end)
	prompt.Parent = gatilho
end

labelMonitor.BackgroundColor3 = Color3.fromRGB(20, 20, 25) 
labelMonitor.TextColor3 = Color3.fromRGB(0, 200, 255)       
labelMonitor.TextXAlignment = Enum.TextXAlignment.Left     
labelMonitor.TextYAlignment = Enum.TextYAlignment.Top

labelMonitor.Text = "  =========================================\n"
	.. "          PAINEL MÉTRICO DE BI & AUDITORIA\n"
	.. "  =========================================\n\n"
	.. "  [MODO EM TEMPO REAL]: Aguardando...\n\n"
	.. "  [MODO ADMINISTRADOR]: Segure 'E'\n"
	.. "  para exportar o banco de dados (CSV) para o Python/Excel."

local function gerarBarraTexto(porcentagem)
	local blocos = math.floor(porcentagem / 10)
	local barra = string.rep("█", blocos) .. string.rep("░", 10 - blocos)
	return barra .. " (" .. porcentagem .. "%)"
end

gatilho:GetAttributeChangedSignal("ProcessarPlayer"):Connect(function()
	local nomePlayer = gatilho:GetAttribute("ProcessarPlayer")
	if nomePlayer == "" then return end

	local player = game.Players:FindFirstChild(nomePlayer)
	if player then
		local pasta = player:FindFirstChild("ResultadosDaltonismo")
		if pasta then
			local d = pasta:FindFirstChild("Deficiente") and pasta.Deficiente.Value or 0
			local p = pasta:FindFirstChild("Protan") and pasta.Protan.Value or 0
			local dt = pasta:FindFirstChild("Deutan") and pasta.Deutan.Value or 0
			local err = pasta:FindFirstChild("Inconsistente") and pasta.Inconsistente.Value or 0
			local errosTotais = d + p + dt

			-- Barras ASCII agora puxam os graus de 0-23
			local pN = errosTotais <= 6 and math.max(0, (6-errosTotais)/4) or 0
			local pM = (errosTotais >= 3 and errosTotais <= 20) and (errosTotais <= 7 and (errosTotais-3)/4 or (errosTotais <= 15 and 1 or (20-errosTotais)/5)) or 0
			local pS = errosTotais >= 16 and math.min(1, (errosTotais-16)/4) or 0

			local pInc = 0
			if err == 1 then pInc = 33 elseif err == 2 then pInc = 66 elseif err > 2 then pInc = math.min(100, err * 10) end
			local pCons = 100 - pInc

			local painelTexto = "  =========================================\n"
				.. "          GRAFO DE PERTINÊNCIA FUZZY (MÉTRICAS)\n"
				.. "  =========================================\n\n"
				.. "  Paciente atual: " .. player.Name .. "\n"
				.. "  Taxa de Auditoria/Consistência: " .. pCons .. "%\n\n"
				.. "  [Azul]    Normal (RG):   " .. gerarBarraTexto(math.floor(pN*100)) .. "\n"
				.. "  [Amarelo] Moderado (RG): " .. gerarBarraTexto(math.floor(pM*100)) .. "\n"
				.. "  [Vermelh] Severo (RG):   " .. gerarBarraTexto(math.floor(pS*100)) .. "\n\n"
				.. "  Variáveis Protan("..p..") Deutan("..dt..")\n"
				.. "  -----------------------------------------\n"
				.. "  👉 Segure 'E' para exportar os dados globais."

			labelMonitor.Text = painelTexto
		end
	end
end)

prompt.Triggered:Connect(function(playerQueAtivou)
	local textoOriginal = labelMonitor.Text
	labelMonitor.Text = "  ⏳ Buscando logs e matrizes de telemetria..."

	local sucesso, listaGlobal = pcall(function() return ClinicaDataStore:GetAsync(CHAVE_MESTRA) end)

	if sucesso and listaGlobal and #listaGlobal > 0 then
		labelMonitor.Text = "  =========================================\n"
			.. "          EXTRAÇÃO CONCLUÍDA!\n"
			.. "  =========================================\n\n"
			.. "  • Registros processados: " .. #listaGlobal .. "\n\n"
			.. "  ✅ Bloco estruturado enviado para o OUTPUT.\n"
			.. "  Aguardando nova interação..."

		local cabecalho = "Nome;UserId;DiagnosticoFinal;Tipo;ScoreAQ;PctNormal;PctLeve;PctModerado;PctSevero;PctConsistencia;PctInconsistencia;TempoTotalSeg"
		for i = 1, 24 do cabecalho = cabecalho .. ";Tempo_Sala_" .. string.format("%02d", i) end
		cabecalho = cabecalho .. ";Trajeto_JSON;DataHora"

		print("\n--- COPIE AS LINHAS ABAIXO E COLE NO SEU EXCEL/PYTHON ---")
		print(cabecalho)

		for _, r in ipairs(listaGlobal) do
			local trajetoFormatado = r.Trajeto
			if type(trajetoFormatado) == "table" then trajetoFormatado = HttpService:JSONEncode(trajetoFormatado)
			elseif not trajetoFormatado or trajetoFormatado == "" then trajetoFormatado = "[]" end

			local linha = string.format("%s;%s;%s;%s;%.2f;%d%%;%d%%;%d%%;%d%%;%d%%;%d%%;%.2f", 
				r.Nome, tostring(r.UserId), r.Diagnostico, r.TipoDaltonismo or "N/A",
				r.ScoreAQ or 0, -- Trocado "Certeza" por ScoreAQ exato
				r.PctNormal or 0, r.PctLeve or 0, r.PctModerado or 0, r.PctSevero or 0, 
				r.PctConsistencia or 100, r.PctInconsistencia or 0, r.TempoTotalSec or 0
			)

			local tSalas = r.TemposSalas
			if type(tSalas) == "string" then pcall(function() tSalas = HttpService:JSONDecode(tSalas) end) end
			if type(tSalas) ~= "table" then tSalas = {} end

			for i = 1, 24 do
				local chave = "Sala_" .. string.format("%02d", i)
				linha = linha .. ";" .. tostring(tSalas[chave] or 0)
			end

			linha = linha .. ";" .. trajetoFormatado .. ";" .. tostring(r.Timestamp)
			print(linha)
		end
		print("--------------------------------------------------------------------\n")
	else
		labelMonitor.Text = "  ❌ ERRO: O banco global está vazio ou inacessível."
		task.wait(4)
		labelMonitor.Text = textoOriginal
	end
end)