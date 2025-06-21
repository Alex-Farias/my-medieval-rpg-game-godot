extends CharacterBody2D

# Constantes de física
const SPEED = 110.0
const GRAVITY = 980
const ACCELERATION = 20
const FRICTION = 10

var player

# Estado do jogador
enum State {IDLE, RUN, ATTACK, HURT, DEATH}
var current_state = State.IDLE
var is_attacking = false
var is_hurt = false
var is_dead = false
var direction = Vector2.ZERO
var was_on_floor = false
var health = 400
var max_health = 400

func _ready():
	# Referência ao player
	player = get_parent().get_node("Player")
	
	# Adicionar Timer para o ataque
	var timer = Timer.new()
	timer.name = "AttackTimer"
	timer.wait_time = 1.0  # Duração da animação de ataque
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
	
	# Adicionar o inimigo ao grupo "enemies"
	add_to_group("enemies")
	
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
	#if was_on_floor and not is_on_floor() and velocity.y >= 0:
		#current_state = State.FALL
	
	was_on_floor = is_on_floor()
	
	# Obter a direção de entrada
	var direction = (player.global_position - global_position).normalized()
	var distance_to_player = (player.global_position - global_position).length()
	
	# Lidar com ataque
	if distance_to_player <= 25 and !is_attacking and !is_hurt:
		is_attacking = true
		current_state = State.ATTACK
		$AttackTimer.start()
	
	# Atualizar a velocidade horizontal com aceleração/desaceleração
	if !is_attacking and !is_hurt:
		if direction.x != 0:
			velocity.x = move_toward(velocity.x, direction.x * SPEED, ACCELERATION)
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION)
	else:
		# Desacelera mais rápido durante ataque ou defesa
		velocity.x = move_toward(velocity.x, 0, FRICTION * 2)
	
	# Atualizar o estado se não estiver em estados especiais
	if !is_attacking and !is_hurt:
		update_state()
	
	# Atualizar a animação
	update_animation()
	
	# Atualizar a direção do sprite
	if direction.x != 0 and !is_attacking and !is_hurt:
		$anim.flip_h = (direction.x < 0)
	
	move_and_slide()

# Determina o estado do inimigo
func update_state():
	if is_on_floor():
		if direction.x == 0:
			current_state = State.IDLE
		else:
			current_state = State.RUN

# Tocar a animação apropriada para o estado atual
func update_animation():
	match current_state:
		State.IDLE:
			$anim.play("idle")
		State.RUN:
			$anim.play("run")
		State.ATTACK:
			$anim.play("attack")
		State.HURT:
			$anim.play("hurt")
		State.DEATH:
			$anim.play("death")
			is_dead = true
			$colision.disabled = true
			$AttackTimer.stop()
			$ComboTimer.stop()
			$HurtTimer.stop()

# Chamado quando o timer de ataque termina
func _on_attack_timer_timeout():
	var distance_to_player = (player.global_position - global_position).length()
	#if distance_to_player <= 25:
		#player.take_damage(5)
	
	is_attacking = false

# Chamado quando o timer de dano termina
func _on_hurt_timer_timeout():
	is_hurt = false

# Função para interagir com objetos
func interact():
	# Cria uma área para detectar objetos interativos à frente do inimigo
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
	health -= amount
	health = max(0, health)
	
	print("Inimigo recebeu " + str(amount) + " de dano. HP: " + str(health))
	
	if health <= 0:
		# Morrer
		current_state = State.DEATH
	else:
		# Entrar no estado de dano
		current_state = State.HURT
		is_hurt = true
		$HurtTimer.start()
