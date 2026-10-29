extends SceneTree
func _initialize() -> void:
	for file in ["arcane_seal.svg","aegis_seal.svg","memory_seal.svg","rune_circle.svg","parchment_scroll.png","answer_scroll.png"]:
		var texture: Texture2D = load("res://assets/ui/grimoire/"+file)
		var image := texture.get_image()
		print(file," dimensions=",texture.get_size()," format=",image.get_format()," alpha=",image.detect_alpha()," corner=",image.get_pixel(0,0)," center=",image.get_pixel(image.get_width()/2,image.get_height()/2))
		image.save_png("res://.local_test/battle_grimoire/probe_"+file.get_basename()+".png")
	quit()
