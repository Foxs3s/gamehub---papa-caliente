extends Control

func _ready() -> void:
	# Asegurarnos de que el menú ocupe los 1280x720
	set_anchors_preset(PRESET_FULL_RECT)
	
	# --- 1. FONDO ---
	# Aquí ponemos un color base oscuro simulando la noche. 
	var fondo_color = ColorRect.new()
	fondo_color.color = Color("1a151f") 
	fondo_color.set_anchors_preset(PRESET_FULL_RECT)
	add_child(fondo_color)
	
	# Si vas a exportar la imagen que te envié para usarla de fondo, descomenta las siguientes líneas:
	# var fondo_imagen = TextureRect.new()
	# fondo_imagen.set_anchors_preset(PRESET_FULL_RECT)
	# fondo_imagen.texture = preload("res://ruta_de_tu_fondo_granja.png")
	# add_child(fondo_imagen)

	# --- 2. CONTENEDOR PRINCIPAL (Centra todo en pantalla) ---
	var centro = CenterContainer.new()
	centro.set_anchors_preset(PRESET_FULL_RECT)
	add_child(centro)

	# Contenedor Vertical para organizar Título, Play y X
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 40)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_child(vbox)

	# --- 3. TÍTULO (Cartel de madera) ---
	var cartel_madera = PanelContainer.new()
	var estilo_madera = StyleBoxFlat.new()
	estilo_madera.bg_color = Color("704d36") # Marrón madera
	estilo_madera.border_width_bottom = 8 # Simula el grosor 3D del pixel art
	estilo_madera.border_color = Color("362214") # Borde oscuro de la madera
	estilo_madera.corner_radius_top_left = 12
	estilo_madera.corner_radius_top_right = 12
	estilo_madera.corner_radius_bottom_left = 12
	estilo_madera.corner_radius_bottom_right = 12
	cartel_madera.add_theme_stylebox_override("panel", estilo_madera)
	
	var margen_cartel = MarginContainer.new()
	margen_cartel.add_theme_constant_override("margin_left", 50)
	margen_cartel.add_theme_constant_override("margin_right", 50)
	margen_cartel.add_theme_constant_override("margin_top", 30)
	margen_cartel.add_theme_constant_override("margin_bottom", 30)
	cartel_madera.add_child(margen_cartel)

	var titulo = Label.new()
	titulo.text = "PAPOI: Capítulo 1\nSangre Y Venganza"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 64)
	titulo.add_theme_color_override("font_color", Color("fcf2d9")) # Letras color crema
	titulo.add_theme_color_override("font_shadow_color", Color("362214")) # Sombra oscura
	# NOTA: Para que se vea pixelado, añade tu fuente .ttf a la carpeta del proyecto y haz esto:
	# titulo.add_theme_font_override("font", preload("res://tu_fuente_pixelada.ttf"))
	margen_cartel.add_child(titulo)
	
	vbox.add_child(cartel_madera)

	# --- 4. BOTÓN PLAY ---
	var btn_play = Button.new()
	btn_play.text = "Play"
	btn_play.custom_minimum_size = Vector2(280, 80)
	btn_play.add_theme_font_size_override("font_size", 50)
	
	var estilo_play = StyleBoxFlat.new()
	estilo_play.bg_color = Color("684b8f") # Morado retro
	estilo_play.border_width_bottom = 8 # Grosor del botón
	estilo_play.border_color = Color("311d4d") # Borde morado oscuro
	estilo_play.corner_radius_top_left = 10
	estilo_play.corner_radius_top_right = 10
	estilo_play.corner_radius_bottom_left = 10
	estilo_play.corner_radius_bottom_right = 10
	btn_play.add_theme_stylebox_override("normal", estilo_play)
	
	# Estilo al pasar el ratón por encima (Hover)
	var estilo_play_hover = estilo_play.duplicate()
	estilo_play_hover.bg_color = Color("7e5ca8") # Morado un poco más claro
	btn_play.add_theme_stylebox_override("hover", estilo_play_hover)
	
	# Conectar la señal de presionar el botón Play
	btn_play.pressed.connect(_on_play_pressed)
	
	# Centrar el botón Play respecto al cartel
	var centro_play = CenterContainer.new()
	centro_play.add_child(btn_play)
	vbox.add_child(centro_play)

	# --- 5. BOTÓN X (Salir) ---
	var btn_salir = Button.new()
	btn_salir.text = "X"
	btn_salir.custom_minimum_size = Vector2(80, 80)
	btn_salir.add_theme_font_size_override("font_size", 48)
	btn_salir.add_theme_color_override("font_color", Color("ffffff"))
	
	var estilo_salir = StyleBoxFlat.new()
	estilo_salir.bg_color = Color("b42b2b") # Rojo intenso
	estilo_salir.border_width_bottom = 8
	estilo_salir.border_color = Color("5c1414") # Borde rojo oscuro
	estilo_salir.corner_radius_top_left = 10
	estilo_salir.corner_radius_top_right = 10
	estilo_salir.corner_radius_bottom_left = 10
	estilo_salir.corner_radius_bottom_right = 10
	btn_salir.add_theme_stylebox_override("normal", estilo_salir)
	
	var estilo_salir_hover = estilo_salir.duplicate()
	estilo_salir_hover.bg_color = Color("db3b3b")
	btn_salir.add_theme_stylebox_override("hover", estilo_salir_hover)
	
	# Conectar la señal de presionar el botón X
	btn_salir.pressed.connect(_on_salir_pressed)
	
	var centro_salir = CenterContainer.new()
	centro_salir.add_child(btn_salir)
	vbox.add_child(centro_salir)

# --- LÓGICA DE LOS BOTONES ---

func _on_play_pressed() -> void:
	print("El jugador presionó Play. Cargando el juego...")
	# Cambia "res://nivel_1.tscn" por la ruta exacta de la escena de tu juego.
	# get_tree().change_scene_to_file("res://nivel_1.tscn")

func _on_salir_pressed() -> void:
	print("Saliendo de PAPOI...")
	get_tree().quit() # Esta línea cierra el programa por completo