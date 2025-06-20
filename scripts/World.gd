# Script para o mundo (World.gd)
extends Node2D

func _ready():
	# Configurações iniciais do mundo
	print("Mundo carregado!")
	print("Player carregado na posição: ", global_position)
	
	
	# Configurar a física global do projeto (se necessário)
	# ProjectSettings.set_setting("physics/2d/default_gravity", 980)
	
	# Iniciar a música de fundo (se tiver)
	if has_node("BackgroundMusic"):
		$BackgroundMusic.play()

# Este script é para um objeto coletável (Collectible.gd)
# ------------------------------------------------
# extends Area2D
# 
# export var item_name = "Moeda"
# export var score_value = 10
# 
# func _ready():
	# Animação de flutuação suave
	# var tween = create_tween().set_loops()
	# tween.tween_property(self, "position:y", position.y - 5, 1.0)
	# tween.tween_property(self, "position:y", position.y + 5, 1.0)
# 
# func _on_body_entered(body):
	# if body.is_in_group("player"):
		# print("Coletou " + item_name)
		# Adicionar pontuação ou efeito
		# if has_node("/root/GameManager"):
			# get_node("/root/GameManager").add_score(score_value)
		# Tocar som
		# $CollectSound.play()
		# Animação de coleta
		# $AnimatedSprite2D.play("collect")
		# await $AnimatedSprite2D.animation_finished
		# Remover da cena
		# queue_free()

# Este script é para uma plataforma móvel (MovingPlatform.gd)
# ------------------------------------------------
# extends AnimatableBody2D
# 
# export var speed = 3.0
# export var move_distance = 100
# export var move_horizontal = true
# 
# var start_position
# var target_position
# 
# func _ready():
	# Salvar posição inicial
	# start_position = position
	# Definir direção de movimento
	# if move_horizontal:
		# target_position = Vector2(position.x + move_distance, position.y)
	# else:
		# target_position = Vector2(position.x, position.y + move_distance)
# 
# func _physics_process(_delta):
	# Movimento de ida e volta
	# var t = (1.0 + sin(Time.get_ticks_msec() / 1000.0 * speed)) / 2.0
	# position = start_position.lerp(target_position, t)

# Este script é para um inimigo básico (Enemy.gd)
# ------------------------------------------------
# extends CharacterBody2D
# 
# export var speed = 50
# export var health = 30
# export var damage = 10
# export var detection_range = 300
# var direction = -1
# var gravity = 980
# var player = null
# 
# func _ready():
	# add_to_group("enemies")
	# $AnimatedSprite2D.play("walk")
# 
# func _physics_process(delta):
	# Aplicar gravidade
	# if not is_on_floor():
		# velocity.y += gravity * delta
	
	# Detectar jogador
	# player = find_player()
	
	# Lógica de movimento
	# if player and position.distance_to(player.position) < detection_range:
		# AI simples: seguir o jogador
		# direction = 1 if player.position.x > position.x else -1
	# else:
		# Patrulhar
		# if is_on_wall() or not $FloorChecker.is_colliding():
			# direction *= -1
			# $FloorChecker.position.x *= -1
	
	# Atualizar velocidade
	# velocity.x = speed * direction
	
	# Atualizar animação
	# $AnimatedSprite2D.flip_h = (direction > 0)
	
	# move_and_slide()
# 
# func find_player():
	# return get_tree().get_nodes_in_group("player").front() if not get_tree().get_nodes_in_group("player").is_empty() else null
# 
# func take_damage(amount):
	# health -= amount
	# if health <= 0:
		# die()
	# else:
		# $AnimatedSprite2D.play("hurt")
		# await $AnimatedSprite2D.animation_finished
		# $AnimatedSprite2D.play("walk")
# 
# func die():
	# $AnimatedSprite2D.play("die")
	# set_physics_process(false)
	# $CollisionShape2D.set_deferred("disabled", true)
	# await $AnimatedSprite2D.animation_finished
	# queue_free()
# 
# func _on_hitbox_body_entered(body):
	# if body.is_in_group("player") and body.has_method("take_damage"):
		# body.take_damage(damage)
