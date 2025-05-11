extends CharacterBody2D

# Constantes de física
const SPEED = 300.0
const RUN_SPEED = 450.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980
const ACCELERATION = 20
const FRICTION = 10

# Estado do jogador
enum State {IDLE, WALK, RUN, JUMP, FALL, ATTACK}
var current_state = State.IDLE
var is_attacking = false
var direction = Vector2.ZERO
var was_on_floor = false

func _physics_process(delta):
	# Adicionar a gravidade
	if not is_on_floor():
		velocity.y += self.GRAVITY * delta
		
	# Detectar se começou a cair
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		current_state = State.FALL
	
	was_on_floor = is_on_floor()
	
	# Lidar com o pulo
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		current_state = State.JUMP
	
	# Obter a direção de entrada
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Verificar se está correndo (shift)
	var is_running = Input.is_action_pressed("ui_shift") 
	var target_speed = RUN_SPEED if is_running else SPEED
	
	# Lidar com ataque (botão direito do mouse)
	if Input.is_action_just_pressed("ui_attack") and not is_attacking:
		is_attacking = true
		current_state = State.ATTACK
		$AttackTimer.start()  # Timer para duração do ataque
	
	# Atualizar a velocidade horizontal com aceleração/desaceleração
	if direction.x != 0:
		velocity.x = move_toward(velocity.x, direction.x * target_speed, ACCELERATION)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION)
	
	# Atualizar o estado se não estiver atacando
	if not is_attacking:
		update_state(is_running)
	
	# Atualizar a animação
	update_animation()
	
	# Atualizar a direção do sprite
	if direction.x != 0:
		$AnimatedSprite2D.flip_h = (direction.x < 0)
	
	move_and_slide()

# Determina o estado do jogador
func update_state(is_running):
	if is_on_floor():
		if direction.x == 0:
			current_state = State.IDLE
		else:
			current_state = State.RUN if is_running else State.WALK
	else:
		if velocity.y < 0:
			current_state = State.JUMP
		else:
			current_state = State.FALL

# Tocar a animação apropriada para o estado atual
func update_animation():
	match current_state:
		State.IDLE:
			$AnimatedSprite2D.play("idle")
		State.WALK:
			$AnimatedSprite2D.play("walk")
		State.RUN:
			$AnimatedSprite2D.play("run")
		State.JUMP:
			$AnimatedSprite2D.play("jump")
		State.FALL:
			$AnimatedSprite2D.play("fall")
		State.ATTACK:
			$AnimatedSprite2D.play("attack")

# Chamado quando o timer de ataque termina
func _on_attack_timer_timeout():
	is_attacking = false
	
# Função para interagir com objetos
func interact():
	# Cria uma área para detectar objetos interativos à frente do jogador
	var interact_position = position + Vector2(30 * sign(1 if not $AnimatedSprite2D.flip_h else -1), 0)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = interact_position
	query.collision_mask = 2  # Use uma camada de colisão específica para interativos
	
	var result = space_state.intersect_point(query)
	if result.size() > 0:
		for r in result:
			if r.collider.has_method("interact"):
				r.collider.interact(self)
				return

# Função para receber dano
func take_damage(amount):
	# Implementar lógica de dano
	print("Jogador recebeu " + str(amount) + " de dano")
	
# Adicionar outros itens necessários para o jogador
func _ready():
	# Adicionar Timer para o ataque
	var timer = Timer.new()
	timer.name = "AttackTimer"
	timer.wait_time = 0.4  # Duração da animação de ataque
	timer.one_shot = true
	add_child(timer)
	timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))
	
	# Adicionar o jogador ao grupo "player"
	add_to_group("player")
	
	# Configurar os controles personalizados se não existirem
	if not InputMap.has_action("ui_shift"):
		var shift_event = InputEventKey.new()
		shift_event.keycode = KEY_SHIFT
		InputMap.add_action("ui_shift")
		InputMap.action_add_event("ui_shift", shift_event)
	
	if not InputMap.has_action("ui_attack"):
		var attack_event = InputEventMouseButton.new()
		attack_event.button_index = MOUSE_BUTTON_RIGHT
		InputMap.add_action("ui_attack")
		InputMap.action_add_event("ui_attack", attack_event)
