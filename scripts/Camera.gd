# Script para configurar a câmera seguindo o jogador
extends Camera2D

var target = null  # Referência ao jogador
var smoothing = 0.1  # Valor de suavização (menor = mais suave)

func _ready():
	# Procura o jogador na cena
	# Ajuste o caminho conforme a estrutura real da sua cena
	target = get_node("../Player") # Considerando que a câmera é filha do Player
	
	if target:
		# Usando o caminho correto para o TileMap
		var tilemap = get_node("../../TileMap") # Ajuste este caminho se necessário
		if tilemap and tilemap.tile_set:
			var map_limits = tilemap.get_used_rect()
			var tile_size = tilemap.tile_set.tile_size # Correto para Godot 4.x
			
			limit_left = map_limits.position.x * tile_size.x
			limit_right = map_limits.end.x * tile_size.x
			limit_top = map_limits.position.y * tile_size.y
			limit_bottom = map_limits.end.y * tile_size.y
		else:
			print("TileMap ou tile_set não encontrado")
	else:
		print("Player não encontrado")

func _process(delta):
	if target:
		# Atualiza a posição da câmera para seguir o jogador suavemente
		global_position = lerp(global_position, target.global_position, smoothing)
