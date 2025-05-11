# Script para configurar a câmera seguindo o jogador
extends Camera2D

var target = null  # Referência ao jogador
var smoothing = 0.1  # Valor de suavização (menor = mais suave)

func _ready():
	# Procura o jogador na cena
	target = get_node("/root/World/Player")
	
	if target:
		# Configurando limites da câmera baseado no tamanho do TileMap
		var tilemap = get_node("/root/World/TileMap")
		if tilemap:
			var map_limits = tilemap.get_used_rect()
			var tile_size = tilemap.cell_size
			
			limit_left = map_limits.position.x * tile_size.x
			limit_right = map_limits.end.x * tile_size.x
			limit_top = map_limits.position.y * tile_size.y
			limit_bottom = map_limits.end.y * tile_size.y

func _process(delta):
	if target:
		# Atualiza a posição da câmera para seguir o jogador suavemente
		global_position = lerp(global_position, target.global_position, smoothing)
