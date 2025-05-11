# Esse é o script para o personagem jogável (Player.gd)
extends CharacterBody2D

# Variáveis do jogador
var speed = 100  # Velocidade de movimento do jogador
var health = 100
var player_name = "Herói"

# Função que é chamada a cada frame
func _physics_process(delta):
	# Pegando os inputs do teclado (setas ou WASD)
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	
	# Normalizando o vetor para evitar movimento mais rápido na diagonal
	if direction.length() > 0:
		direction = direction.normalized()
		$AnimatedSprite2D.play("walk")  # Inicia a animação de andar
	else:
		$AnimatedSprite2D.play("idle")  # Inicia a animação de parado
	
	# Ajustando a direção do sprite baseado na direção do movimento
	if direction.x != 0:
		$AnimatedSprite2D.flip_h = direction.x < 0
	
	# Setando a velocidade do personagem
	velocity = direction * speed
	
	# Movendo o personagem
	move_and_slide()
	
	# Verificando interações quando o jogador pressiona a tecla de ação (E)
	if Input.is_action_just_pressed("ui_accept"):  # Pode ser alterado para outra tecla
		interact()

# Função para interagir com objetos próximos
func interact():
	# Verificando se há algum objeto interativo próximo
	var interactives = $InteractionArea.get_overlapping_areas()
	for object in interactives:
		if object.has_method("interact"):
			object.interact(self)

# Função para receber dano
func take_damage(amount):
	health -= amount
	if health <= 0:
		die()

# Função de morte do personagem
func die():
	# Reinicia o nível ou mostra game over
	get_tree().reload_current_scene()

# Função para curar o personagem
func heal(amount):
	health += amount
	if health > 100:
		health = 100

# -------------------------------------------------------------------------------
# Esse é o script para um NPC básico (NPC.gd)
extends Area2D

export var npc_name = "Aldeão"
export var dialogue = ["Olá viajante!", "Como posso ajudar você?"]
var dialogue_index = 0
var in_dialogue = false
var player_ref = null

func _ready():
	# Conecta o sinal de área de entrada para detectar quando o jogador está próximo
	connect("body_entered", self, "_on_body_entered")
	connect("body_exited", self, "_on_body_exited")

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_ref = body
		$InteractionPrompt.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_ref = null
		$InteractionPrompt.visible = false
		end_dialogue()

func interact(player):
	if !in_dialogue:
		start_dialogue()
	else:
		next_dialogue()

func start_dialogue():
	in_dialogue = true
	dialogue_index = 0
	show_dialogue()

func next_dialogue():
	dialogue_index += 1
	if dialogue_index < dialogue.size():
		show_dialogue()
	else:
		end_dialogue()

func show_dialogue():
	# Aqui você conectaria com seu sistema de diálogo UI
	# Para este exemplo simples, vamos apenas imprimir no console
	print(npc_name + ": " + dialogue[dialogue_index])
	
	# Se você tiver um UI de diálogo, use algo como:
	# get_tree().get_root().get_node("DialogueUI").show_text(npc_name, dialogue[dialogue_index])

func end_dialogue():
	in_dialogue = false
	dialogue_index = 0
	# Esconda o UI de diálogo aqui

# -------------------------------------------------------------------------------
# Esse é o script para um item coletável (Item.gd)
extends Area2D

export var item_name = "Poção de Cura"
export var item_description = "Recupera 20 pontos de vida."
export var health_restore = 20

func _ready():
	# Conecta o sinal para detectar colisão com o jogador
	connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
	if body.is_in_group("player"):
		collect(body)

func collect(player):
	print("Coletou: " + item_name)
	
	# Aplicar o efeito da poção
	if health_restore > 0:
		player.heal(health_restore)
	
	# Removendo o item do mundo após coletar
	queue_free()

# -------------------------------------------------------------------------------
# Esse é o script para o sistema de diálogo UI (DialogueUI.gd)
extends CanvasLayer

var active = false

func _ready():
	$DialoguePanel.visible = false

func show_text(speaker_name, text):
	$DialoguePanel.visible = true
	$DialoguePanel/SpeakerName.text = speaker_name
	$DialoguePanel/DialogueText.text = text
	active = true

func hide_dialogue():
	$DialoguePanel.visible = false
	active = false

func _input(event):
	if active and event.is_action_pressed("ui_accept"):
		hide_dialogue()

# -------------------------------------------------------------------------------
# Esse é o script para o controlador do jogo (GameManager.gd)
extends Node

# Referências a cenas
var player_scene = preload("res://Player.tscn")

# Estado do jogo
var player_gold = 0
var quests_completed = 0
var game_time = 0
var day_time = true  # true = dia, false = noite

func _ready():
	# Inicializa o jogo
	print("Bem-vindo ao RPG Medieval!")

func _process(delta):
	# Atualiza o tempo do jogo
	game_time += delta
	
	# A cada 300 segundos (5 minutos), alterna entre dia e noite
	if int(game_time) % 300 == 0:
		toggle_day_night()

func toggle_day_night():
	day_time = !day_time
	print("Agora é " + ("dia" if day_time else "noite"))
	
	# Aqui você pode alterar a iluminação do mundo
	# get_tree().call_group("lights", "set_enabled", !day_time)

func add_gold(amount):
	player_gold += amount
	print("Ouro atual: " + str(player_gold))

func complete_quest():
	quests_completed += 1
	print("Missão concluída! Total: " + str(quests_completed))

func save_game():
	# Código básico para salvar o jogo (implementação simples)
	var save_data = {
		"player_gold": player_gold,
		"quests_completed": quests_completed,
		"game_time": game_time,
		"player_health": get_node("/root/World/Player").health,
		"player_position": {
			"x": get_node("/root/World/Player").position.x,
			"y": get_node("/root/World/Player").position.y
		}
	}
	
	# Salvando os dados em um arquivo
	var file = File.new()
	file.open("user://save_game.dat", File.WRITE)
	file.store_var(save_data)
	file.close()
	
	print("Jogo salvo com sucesso!")

func load_game():
	var file = File.new()
	if file.file_exists("user://save_game.dat"):
		file.open("user://save_game.dat", File.READ)
		var save_data = file.get_var()
		file.close()
		
		# Carregando os dados salvos
		player_gold = save_data.player_gold
		quests_completed = save_data.quests_completed
		game_time = save_data.game_time
		
		# Atualizando o jogador
		var player = get_node("/root/World/Player")
		player.health = save_data.player_health
		player.position.x = save_data.player_position.x
		player.position.y = save_data.player_position.y
		
		print("Jogo carregado com sucesso!")
	else:
		print("Nenhum jogo salvo encontrado.")
