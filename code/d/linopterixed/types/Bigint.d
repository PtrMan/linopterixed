module linopterixed.types.Bigint;

import std.stdint;

import misced.BinaryHelpers;


struct Bigint(uint multiplesOf64Bits) {
	private uint32_t[multiplesOf64Bits*2] data32; // for a 32 bit system

	final uint32_t accessor32(size_t i) pure const {
		assert(i < data32.length);
		return data32[i]; // for a 32 bit system
	}

	final uint32_t accessor32(size_t i, uint32_t value) pure {
		assert(i < data32.length);
		data32[i] = value;
		return value; // for a 32 bit system
	}

	// TODO< write unittest >

	final Bigint!multiplesOf64Bits shiftRight(size_t shift) /*pure*/ const {
		assert(shift < 32); // not jet implemented for big shifts

		Bigint!multiplesOf64Bits result;

		// 32 bit impl
		uint32_t remainer = 0; // rigth most bits from the previous number
		for( int i = data32.length-1; i >= 0; i-- ) {
			uint32_t oldRemainer = remainer;
			remainer = data32[i] & maskForBits!uint32_t(shift);
			result.data32[i] = (data32[i] >> shift) | (oldRemainer << (uint32_t.sizeof*8-shift));
		}

		return result;
	}

	// TODO< write unittest >

	final Bigint!multiplesOf64Bits shiftLeft(size_t shift) pure const {
		assert(shift < 32); // not jet implemented for big shifts

		Bigint!multiplesOf64Bits result;

		// 32 bit impl
		uint32_t remainer = 0; // rigth most bits from the previous number
		foreach( i; 0..data32.length ) {
			uint32_t oldRemainer = remainer;
			remainer = (data32[i] >> (uint32_t.sizeof*8-shift)) & maskForBits!uint32_t(shift);
			result.data32[i] = (data32[i] << shift) | remainer;
		}

		return result;
	}

	final bool getBit(size_t bit) const pure {
		// version for 32 bit machines
		uint32_t mask = (1 << (bit % (uint32_t.sizeof*8)));
		return (data32[bit/(uint32_t.sizeof*8)] & mask) != 0;
	}

	final void setBit(size_t bit, bool value) {
		// version for 32 bit machines
		uint32_t mask = (1 << (bit % (uint32_t.sizeof*8)));
		uint32_t masked = ~mask & data32[bit/(uint32_t.sizeof*8)];
		uint32_t valueAsMask = cast(uint32_t)value << (bit % (uint32_t.sizeof*8));
		data32[bit/(uint32_t.sizeof*8)] = masked | valueAsMask;
	}

	unittest {
		{ // set bit to false
			Bigint!1 x;
			x.accessor32(0, 3);
			x.setBit(1, false);

			assert(x.accessor32(0) == 1);
		}

		{ // set bit which is true to true
			Bigint!1 x;
			x.accessor32(0, 3);
			x.setBit(0, true);

			assert(x.accessor32(0) == 3);
		}

		{ // set bit which is false to false
			Bigint!1 x;
			x.accessor32(0, 2);
			x.setBit(0, false);

			assert(x.accessor32(0) == 2);
		}

		{ // set bit of next 32-bit number to true
			Bigint!1 x;
			
			x.setBit(32, true);

			assert(x.accessor32(1) == 1);
		}

		{ // set bit of next 32-bit number to false
			Bigint!1 x;

			x.accessor32(1, 1);
			x.setBit(32, false);

			assert(x.accessor32(1) == 0);
		}

	}

	final Bigint!multiplesOf64Bits booleanNegation() pure const {
		Bigint!multiplesOf64Bits result;
		
		// version for 32 bit systems
		foreach( i; 0..multiplesOf64Bits*2 ) {
			result.data32[i] = ~data32[i];
		}

		return result;
	}

	static void booleanAnd(Bigint!multiplesOf64Bits a, Bigint!multiplesOf64Bits b, ref Bigint!multiplesOf64Bits result) {
		// for a 32 bit system
		foreach( i; 0..multiplesOf64Bits*2 ) {
			result.data32[i] = a.data32[i] & b.data32[i];
		}
	}


	static bool greater(Bigint!multiplesOf64Bits a, Bigint!multiplesOf64Bits b) {
		// 32 bit impl
		for( int i = multiplesOf64Bits*2-1; i >= 0; i-- ) {
			if(a.data32[i] > b.data32[i] ) {
				return true;
			}
		}

		return false;
	}

	static bool greaterEqual(Bigint!multiplesOf64Bits a, Bigint!multiplesOf64Bits b) {
		// 32 bit impl
		for( int i = multiplesOf64Bits*2-1; i >= 0; i-- ) {
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
