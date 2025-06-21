extends CharacterBody2D

# Constantes de física
const SPEED = 150.0
const RUN_SPEED = 350.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980
const ACCELERATION = 20
const FRICTION = 10

# Estado do jogador
enum State {IDLE, WALK, RUN, JUMP, FALL, ATTACK1, ATTACK2, ATTACK3, DEFEND, HURT, DEATH}
var current_state = State.IDLE
var is_attacking = false
var is_defending = false
var is_hurt = false
var is_dead = false
var attack_damage = 400
var attack_combo = 0
var combo_timer = 0
var direction = Vector2.ZERO
var was_on_floor = false
var health = 100
var max_health = 100

func _ready():
	# Adicionar Timer para o ataque
	var timer = Timer.new()
	timer.name = "AttackTimer"
	timer.wait_time = 0.6  # Duração da animação de ataque
	timer.one_shot = true
	add_child(timer)
	timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))
	
	# Adicionar Timer para o combo de ataques
	var combo_timer_node = Timer.new()
	combo_timer_node.name = "ComboTimer"
	combo_timer_node.wait_time = 1.5  # Tempo para realizar o próximo ataque do combo
	combo_timer_node.one_shot = true
	add_child(combo_timer_node)
	combo_timer_node.connect("timeout", Callable(self, "_on_combo_timer_timeout"))
	
	# Adicionar Timer para o estado de dano
	var hurt_timer = Timer.new()
	hurt_timer.name = "HurtTimer"
	hurt_timer.wait_time = 0.5  # Tempo do estado de dano
	hurt_timer.one_shot = true
	add_child(hurt_timer)
	hurt_timer.connect("timeout", Callable(self, "_on_hurt_timer_timeout"))
	
	$AttackArea.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))
	
	# Adicionar o jogador ao grupo "player"
	add_to_group("player")
	
	# Começar com a animação idle
	$anim.play("idle")

func _physics_process(delta):
	# Se morto, apenas animar a morte
	if is_dead:
		return
		
	# Adicionar a gravidade
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		
	# Detectar se começou a cair
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		current_state = State.FALL
	
	was_on_floor = is_on_floor()
	
	# Lidar com o pulo
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and !is_attacking and !is_defending and !is_hurt:
		velocity.y = JUMP_VELOCITY
		current_state = State.JUMP
	
	# Obter a direção de entrada
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Verificar se está correndo (shift)
	var is_running = Input.is_action_pressed("ui_shift") and !is_attacking and !is_defending and !is_hurt
	var target_speed = RUN_SPEED if is_running else SPEED
	
	# Lidar com defesa
	if Input.is_action_pressed("ui_down") and is_on_floor() and !is_attacking and !is_hurt:
		is_defending = true
		current_state = State.DEFEND
		velocity.x = 0 # Não pode se mover enquanto defende
	else:
		is_defending = false
	
	# Lidar com ataque (botão direito do mouse)
	if Input.is_action_just_pressed("ui_attack") and !is_defending and !is_hurt:
		is_attacking = true
		$AttackArea.monitoring = true  # Ativa quando inicia o ataque
		
		# Sistema de combo de ataques
		if $ComboTimer.is_stopped():
			attack_combo = 0
		
		attack_combo = (attack_combo + 1) % 4
		if attack_combo == 0:
			attack_combo = 1
		
		match attack_combo:
			1:
				current_state = State.ATTACK1
			2:
				current_state = State.ATTACK2
			3:
				current_state = State.ATTACK3
		
		$AttackTimer.start()  # Timer para duração do ataque
		$ComboTimer.start()   # Timer para o próximo ataque do combo
		
	# Atualizar a direção do AttackArea com base no flip
	if $anim.flip_h:
		$AttackArea.position.x = -30
	else:
		$AttackArea.position.x = 30

	
	# Atualizar a velocidade horizontal com aceleração/desaceleração
	if !is_attacking and !is_defending and !is_hurt:
		if direction.x != 0:
			velocity.x = move_toward(velocity.x, direction.x * target_speed, ACCELERATION)
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION)
	else:
		# Desacelera mais rápido durante ataque ou defesa
		velocity.x = move_toward(velocity.x, 0, FRICTION * 2)
	
	# Atualizar o estado se não estiver em estados especiais
	if !is_attacking and !is_defending and !is_hurt:
		update_state(is_running)
	
	# Atualizar a animação
	update_animation()
	
	# Atualizar a direção do sprite
	if direction.x != 0 and !is_attacking and !is_defending and !is_hurt:
		$anim.flip_h = (direction.x < 0)
	
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
			$anim.play("idle")
		State.WALK:
			$anim.play("walk")
		State.RUN:
			$anim.play("run")
		State.JUMP:
			$anim.play("jump")
		State.FALL:
			 #Se não tiver animação de queda específica, pode usar jump
			if $anim.sprite_frames.has_animation("fall"):
				$anim.play("fall")
			else:
				$anim.play("jump")
		State.ATTACK1:
			$anim.play("attack1")
		State.ATTACK2:
			$anim.play("attack2")
		State.ATTACK3:
			$anim.play("attack3")
		State.DEFEND:
			$anim.play("defend")
		State.HURT:
			$anim.play("hurt")
		State.DEATH:
			$anim.play("death")
			is_dead = true

# Chamado quando o timer de ataque termina
func _on_attack_timer_timeout():
	$AttackArea.monitoring = false  # Desativa após o ataque
	is_attacking = false

# Chamado quando o timer de combo termina
func _on_combo_timer_timeout():
	attack_combo = 0

# Chamado quando o timer de dano termina
func _on_hurt_timer_timeout():
	is_hurt = false

func _on_attack_area_body_entered(body):
	if is_attacking and body.is_in_group("enemies"):
		body.take_damage(attack_damage * attack_combo)

# Função para interagir com objetos
func interact():
	# Cria uma área para detectar objetos interativos à frente do jogador
	var interact_position = position + Vector2(30 * sign(1 if not $anim.flip_h else -1), 0)
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
	if is_defending:
		# Reduz o dano quando está defendendo
		amount = amount / 2
	
	health -= amount
	health = max(0, health)
	
	print("Jogador recebeu " + str(amount) + " de dano. HP: " + str(health))
	
	if health <= 0:
		# Morrer
		current_state = State.DEATH
		update_animation()
	else:
		# Entrar no estado de dano
		current_state = State.HURT
		is_hurt = true
		$HurtTimer.start()
