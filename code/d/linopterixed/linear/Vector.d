module linopterixed.linear.Vector;

import core.simd;

struct SpatialVectorStruct(uint Size, Type, bool Scalable = true) {
    private alias SpatialVectorStruct!(Size, Type, Scalable) ThisType;
    alias Type ComponentType;
    

    final void opAssign(typeof(this) rhs) {
        foreach( i; 0..Size ) {
            this[i] = rhs[i];
        }
    }

    final ThisType clone() {
        ThisType result;

        foreach( i; 0..Size ) {
            result[i] = this[i];
        }
        return result;
    }

    static ThisType make(Type[Size] parameter ...) {
        ThisType result;
        foreach( size_t i; 0..Size ) {
            result[i] = parameter[i];
        }
        return result;
    }

    /* uncommented because we can't anymore access the raw pointer easily, because its either an array or an array of vectors
    final @property Type* ptr() {
        return data.ptr;
    }
    */



	protected const uint ALIGNMENTSIZE = ((Size/4) + ((Size % 4) != 0 ? 1 : 0)) * 4;

	protected enum ISSIMDDOUBLE4ARRAY = is(Type==double) && is(double4);
	protected enum ISSIMDFLOAT4ARRAY = is(Type==float) && is(float4);
	protected enum ISSIMDARRAY = ISSIMDDOUBLE4ARRAY || ISSIMDFLOAT4ARRAY;

	static if( ISSIMDDOUBLE4ARRAY || ISSIMDFLOAT4ARRAY ) {
		static if ( ISSIMDDOUBLE4ARRAY ) {
			protected align(16) double4 vectorArray[ALIGNMENTSIZE/4];
		}
		else static if ( ISSIMDFLOAT4ARRAY ) {
			protected align(16) float4 vectorArray[ALIGNMENTSIZE/4];
		}
	}
	else {
		protected align(16) Type array[ALIGNMENTSIZE];
	}


	// accessors for value access
	final Type opIndexAssign(Type value, size_t index) {
		static if( ISSIMDARRAY ) {
			return vectorArray[index/4].array[index%4] = value;
		}
		else {
			return array[index] = value;
		}
	}
		
	final Type opIndex(size_t index) const {
		static if( ISSIMDARRAY ) {
			return vectorArray[index/4].array[index%4];
		}
		else {
			return array[index];
		}
	}


    final typeof(this) opBinary(string op)(Type rhs) const {
    	ThisType result;

        static if (op == "*") {
            static if (!Scalable) {
                static assert(0, "SpatialVector is not scalable!");
            }

            foreach( i; 0..Size ) {
                result[i] = this[i] * rhs;
            }
            
            return result;
        }
        else {
            static assert(0, "Operator "~op~" not implemented");
        }
    }
    
    final typeof(this) opOpAssign(string op)(typeof(this) rhs) {
        static if (op == "+") {
        	static if( ISSIMDARRAY && __traits(compiles, this.vectorArray[0]+=rhs.vectorArray[0]) ) {
        		foreach( i; 0..this.vectorArray.length ) {
        			this.vectorArray[i]+=rhs.vectorArray[i];
        		}
        	}
        	else {
	            foreach( i; 0..Size ) {
	                this.array[i] += rhs.array[i];
	            }
        	}
        }
        else static if (op == "-") {
            static if( ISSIMDARRAY && __traits(compiles, this.vectorArray[0]-=rhs.vectorArray[0]) ) {
        		foreach( i; 0..this.vectorArray.length ) {
        			this.vectorArray[i]-=rhs.vectorArray[i];
        		}
        	}
        	else {
	            foreach( i; 0..Size ) {
	                this.array[i] -= rhs.array[i];
	            }
        	}
        }
        else {
            static assert(0, "Operator "~op~" not implemented");
        }

        return this;
    }

    final typeof(this) opBinary(string op)(const typeof(this) rhs) const {
        SpatialVectorStruct!(Size, Type, Scalable) result;
        
        static if (op == "+") {
        	static if( ISSIMDARRAY && __traits(compiles, this.vectorArray[0]+rhs.vectorArray[0]) ) {
        		foreach( i; 0..this.vectorArray.length ) {
        			result.vectorArray[i] = this.vectorArray[i]+rhs.vectorArray[i];
        		}
        	}
        	else {
	            foreach( i; 0..Size ) {
	                result.array[i] = this.array[i] + rhs.array[i];
	            }
        	}

            return result;
        }
        else static if (op == "-") {
            static if( ISSIMDARRAY && __traits(compiles, this.vectorArray[0]-rhs.vectorArray[0]) ) {
        		foreach( i; 0..this.vectorArray.length ) {
        			result.vectorArray[i] = this.vectorArray[i]-rhs.vectorArray[i];
        		}
        	}
        	else {
	            foreach( i; 0..Size ) {
	                result.array[i] = this.array[i] - rhs.array[i];
	            }
        	}

            return result;
        }
        else {
            static assert(0, "Operator "~op~" not implemented");
        }
    }


    final @property Type x() const {
        return this[0];
    }

    final @property Type x(Type value) {
        return this[0] = value;
    }

    final @property Type y() const {
        return this[1];
    }

    final @property Type y(Type value) {
        return this[1] = value;
    }

    static if (Size >= 3) {
        final @property Type z() const {
            return this[2];
        }

        final @property Type z(Type value) {
            return this[2] = value;
        }
    }
    
    static if (Size >= 4) {
        final @property Type w() const {
            return this[3];
        }

        final @property Type w(Type value) {
            return this[3] = value;
        }
    }
}




unittest {
    alias SpatialVectorStruct!(5, float) VectorType;
    { // addition
        VectorType vecA, vecB;
        vecA[0] = 1.0f;
        vecB[0] = 2.0f;
        vecA[4] = 4.0f;
        vecB[4] = 8.0f;
        VectorType vecResult = vecA + vecB;
        assert(vecResult[0] == 3.0f);
        assert(vecResult[4] == 12.0f);
    }

    { // mul
        VectorType vecB;
        vecB[0] = 2.0f;
        vecB[4] = 8.0f;
        VectorType vecResult = vecB*4.0f;
        assert(vecResult[0] == 8.0f);
        assert(vecResult[4] == 32.0f);
    }
}

// TODO< generalize to more and put it into the mixin to optimize >
/* uncommented because its the old class version
SpatialVector!(3, Type) componentDivision(Type)(SpatialVector!(3, Type) vector, SpatialVector!(3, Type) divisorVector) {
	return new SpatialVector!(3, Type)(vector.x / divisorVector.x, vector.y / divisorVector.y, vector.z / divisorVector.z);
}*/

SpatialVectorStruct!(2, Type) componentMultiplication(Type)(SpatialVectorStruct!(2, Type) vector, SpatialVectorStruct!(2, Type) other) {
    return SpatialVectorStruct!(2, Type).make(vector.x * other.x, vector.y * other.y);
}


// method for better readability
SpatialVectorStruct!(Size, Type, true) scale(uint Size, Type)(SpatialVectorStruct!(Size, Type, true) vector, Type magnitude) {
    return cast(SpatialVectorStruct!(Size, Type, true))(vector * magnitude);
}

import std.math : sqrt;

Type magnitude(Type, uint Size, bool Scalable)(SpatialVectorStruct!(Size, Type, Scalable) vector) {
    return cast(Type)sqrt(vector.magnitudeSquared());
}



Type magnitudeSquared(Type, uint Size, bool Scalable)(SpatialVectorStruct!(Size, Type, Scalable) vector) {
    return dot(vector, vector);
}


SpatialVectorStruct!(Size, Type) normalized(uint Size, Type)(SpatialVectorStruct!(Size, Type) vector) {
    Type length = magnitude(vector);
    return vector.scale(cast(Type)1.0 / length);
}

// TODO< put this into the mixin class and optimize it using core.simd intrinsics or LDC LLVM inline magic >
Type dot(uint Size, Type, bool Scalable)(SpatialVectorStruct!(Size, Type, Scalable) a, SpatialVectorStruct!(Size, Type, Scalable) b) {
    Type result = cast(Type)0;

    // NOTE< dmd compiler is as of v2.063 was too stupid to optimize this, doesn't matter much because ldc should produce better code >
    foreach( index; 0..Size ) {
        result = result + a[index]*b[index];
    }

    return result;
}

unittest {
	alias SpatialVectorStruct!(4, float) VectorType;

	VectorType vecA, vecB;
    vecA[0] = 1.0f;
    vecB[0] = 2.0f;
    vecA[1] = 2.0f;
    vecB[1] = 4.0f;
    vecA[2] = 4.0f;
    vecB[2] = 8.0f;
    vecA[3] = 8.0f;
    vecB[3] = 16.0f;
    assert( dot(vecA, vecB) == 170.0f);
}

SpatialVectorStruct!(3, Type, Scalable) crossProduct(Type, Scalable)(SpatialVectorStruct!(3, Type, Scalable) a, SpatialVectorStruct!(3, Type, Scalable) b) {
	Type x = a.data[1] * b.data[2] - a.data[2] * b.data[1];
	Type y = a.data[2] * b.data[0] - a.data[0] * b.data[2];
	Type z = a.data[0] * b.data[1] - a.data[1] * b.data[0];
	return SpatialVectorStruct!(3, Type, Scalable).make(x, y, z);
}
