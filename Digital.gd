extends RefCounted
class_name D


#region Digital Manipulation Helper Functions
## How many digits are in a number?
static func digit_count(num:int, base:int=16) -> int:
	if num == 0 or base < 2:
		return 1
	else:
		return floori(log(num) / log(base) + 1)
 
## Get a mask of all 1 with given amount of bits, in other words the greatest number you can represent with given amount of bits.
static func greatest(width:int) -> int:
	return (1 << width) - 1

## Concatenate two integers
static func join(A:int, B:int, A_width:=8, B_width:=8) -> int:
	A &= greatest(A_width)
	B &= greatest(B_width)
	return A << B_width | B

## Remove bits that are too large to fit the given amount of bits. Returns only the least significant part.
static func trim(A:int, width:int=16) -> int:
	return A & greatest(width)

## Split an int into two, based on the bit amount of the least significant half.
static func split(AB:int, lsb_width:int) -> Vector2i:
	var A = AB >> lsb_width
	var B = AB & greatest(lsb_width)
	return Vector2i(A,B)

## Given a value that's too big to fit the bit width, it splits into as many ints that fit as necessary.
static func breakdown(A:int, width:int) -> PackedInt32Array:
	var max_int = greatest(width)
	var ans : PackedInt32Array
	var s = split(A, width)
	ans.append(s.y)
	while s.x > max_int:
		s = split(s.x, width)
		ans.append(s.y)
	ans.reverse()
	return ans

#endregion


## Decode a complex expression that could be used in assembly to produce an integer.
static func to_val(expr:String, wid:int):
	var val : int = 0
	var negative : bool = false
	
	if expr[0] == "-":
		expr = expr.right(-1)
		negative = true
	elif expr[0] == "+":
		expr = expr.right(-1)
	
	
	match expr[0]:
		"x":
			val = expr.right(-1).hex_to_int()
		_:
			val = expr.to_int()
	
	if negative:
		val = greatest(wid) ^ val
		return val + 1
	else:
		return val
