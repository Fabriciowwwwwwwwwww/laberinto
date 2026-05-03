extends Node

var experiencia_total: int = 0
var nivel: int = 1
var exp_actual: int = 0
var exp_necesaria: int = 20

signal experiencia_cambiada(exp_actual, exp_necesaria, nivel)

func agregar_experiencia(cantidad: int):
	print("📊 XP recibida:", cantidad)

	exp_actual += cantidad
	experiencia_total += cantidad

	print("📈 XP actual:", exp_actual, "/", exp_necesaria)

	if exp_actual >= exp_necesaria:
		print("🎉 SUBE DE NIVEL")
		subir_nivel()

	emit_signal("experiencia_cambiada", exp_actual, exp_necesaria, nivel)

func subir_nivel():
	exp_actual -= exp_necesaria
	nivel += 1
	exp_necesaria = int(exp_necesaria * 1.5)

	print("🆙 Nivel:", nivel)
