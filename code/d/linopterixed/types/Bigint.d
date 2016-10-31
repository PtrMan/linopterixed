module linopterixed.types.Bigint;

import std.stdint;

struct Bigint(uint multiplesOf64Bits) {
	private uint32_t[multiplesOf64Bits*2] data32; // for a 32 bit system

	final uint32_t accessor32(size_t i) pure {
		assert(i < data32.length);
		return data32[i]; // for a 32 bit system
	}

	final uint32_t accessor32(size_t i, uint32_t value) pure {
		assert(i < data32.length);
		data32[i] = value;
		return value; // for a 32 bit system
	}

	static void booleanAnd(const Bigint!multiplesOf64Bits a, const Bigint!multiplesOf64Bits b, ref Bigint!multiplesOf64Bits result) {
		// for a 32 bit system
		foreach( i; 0..multiplesOf64Bits*2 ) {
			result.data32[i] = a.data32[i] & b.data32[i];
		}
	}

	static bool greater(const Bigint!multiplesOf64Bits a, const Bigint!multiplesOf64Bits b) {
		// 32 bit impl
		for( size_t i = multiplesOf64Bits*2-1; i >= 0; i-- ) {
			if(a.data32[i] > b.data32[i] ) {
				return true;
			}
		}

		return false;
	}

	static bool greaterEqual(Bigint!multiplesOf64Bits a, Bigint!multiplesOf64Bits b) {
		// 32 bit impl
		for( size_t i = multiplesOf64Bits*2-1; i >= 0; i-- ) {
			if( a.data32[i] >= b.data32[i] ) {
				return true;
			}
		}

		return false;
	}

	// used for interpretation as signed integer
	static bool checkMostSignificantBit(Bigint!multiplesOf64Bits value) {
		// 32 bit impl
		return (value.data32[multiplesOf64Bits*2-1] & (1 << (uint32_t.sizeof*8-1))) != 0;
	}

	// for a 32 bit system
	static void add(Bigint!multiplesOf64Bits a, Bigint!multiplesOf64Bits b, ref Bigint!multiplesOf64Bits result) {
		// we need temporary arrays because it simplifies the assembly code
		uint32_t[multiplesOf64Bits*2] aArr, resultArr;
		
		// but we need also the move the data around
		foreach( i; 0..multiplesOf64Bits*2 ) {
			aArr[i] = a.data32[i];
			resultArr[i] = b.data32[i];
		}

		asm {
			mov EAX, aArr[0];
			add [resultArr[0]], EAX;
		}

		import std.format : format;
		import std.string : join;
		import std.algorithm.iteration : map;
		import std.range : iota;
		mixin(iota(1,multiplesOf64Bits*2).map!(n => "asm{mov EAX, aArr[%s*4];adc [resultArr[%s*4]], EAX;}".format(n, n)).join);

		foreach( i; 0..multiplesOf64Bits*2 ) {
			result.data32[i] = resultArr[i];
		}
	}
}
