extends RefCounted
class_name NumberFormatter

const THOUSAND := 1000.0
const MILLION := 1000000.0
const BILLION := 1000000000.0
const TRILLION := 1000000000000.0

static func amount(value: float) -> String:
	var absolute_value: float = abs(value)

	if absolute_value < THOUSAND:
		return _format_small_amount(value)

	if absolute_value < MILLION:
		return _format_scaled_amount(value, THOUSAND, "K")

	if absolute_value < BILLION:
		return _format_scaled_amount(value, MILLION, "M")

	if absolute_value < TRILLION:
		return _format_scaled_amount(value, BILLION, "B")

	return _format_scaled_amount(value, TRILLION, "T")


static func integer_amount(value: int) -> String:
	var float_value: float = float(value)
	var absolute_value: float = abs(float_value)

	if absolute_value < THOUSAND:
		return str(value)

	return amount(float_value)


static func cost(value: float) -> String:
	return amount(value)


static func multiplier(value: float) -> String:
	return "x%.3f" % value


static func percent(value: float) -> String:
	var percent_value: float = value * 100.0

	if abs(percent_value) < 10.0:
		return "%.1f%%" % percent_value

	return "%.0f%%" % percent_value


static func signed_percent(value: float) -> String:
	var percent_value: float = value * 100.0

	if percent_value >= 0.0:
		if abs(percent_value) < 10.0:
			return "+%.1f%%" % percent_value

		return "+%.0f%%" % percent_value

	if abs(percent_value) < 10.0:
		return "%.1f%%" % percent_value

	return "%.0f%%" % percent_value


static func percent_from_multiplier(value: float) -> String:
	var percent_delta: float = value - 1.0
	return signed_percent(percent_delta)


static func precise_percent_from_multiplier(value: float) -> String:
	var percent_delta: float = (value - 1.0) * 100.0

	if percent_delta >= 0.0:
		return "+%.2f%%" % percent_delta

	return "%.2f%%" % percent_delta


static func seconds(value: float) -> String:
	return "%.2fs" % value


static func ratio(current_value: float, target_value: float) -> String:
	return "%s / %s" % [
		amount(current_value),
		amount(target_value)
	]


static func _format_small_amount(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))

	return "%.2f" % value


static func _format_scaled_amount(value: float, divisor: float, suffix: String) -> String:
	var scaled_value: float = value / divisor

	if abs(scaled_value) >= 100.0:
		return "%.0f%s" % [scaled_value, suffix]

	if abs(scaled_value) >= 10.0:
		return "%.1f%s" % [scaled_value, suffix]

	return "%.2f%s" % [scaled_value, suffix]

static func signed_amount(value: float) -> String:
	if value >= 0.0:
		return "+%s" % amount(value)

	return "-%s" % amount(abs(value))
