//TEST(compute):COMPARE_COMPUTE:-cpu -xslang -disable-specialization
//DISABLE_TEST(compute):COMPARE_COMPUTE:-cuda -xslang -disable-specialization

// Test dynamic dispatch code gen for initializing an extential value
// from a generic value.

[anyValueSize(16)]
interface IInterface
{
	int Compute(int inVal);
};

int GenericCompute0(IInterface obj, int inVal)
{
    return obj.Compute(inVal);
}

int GenericCompute1<T:IInterface>(T obj, int inVal)
{
    IInterface iobj = obj;
	return iobj.Compute(inVal) + 
        GenericCompute0(obj, inVal) -
        GenericCompute0(iobj, inVal);
}


struct Impl : IInterface
{
    int base;
	int Compute(int inVal) { return base + inVal * inVal; }
};

int test(int inVal)
{
    Impl obj;
    obj.base = 1;
	return GenericCompute1(obj, inVal);
}

//TEST_INPUT:ubuffer(data=[0 1 2 3], stride=4):out,name=outputBuffer
RWStructuredBuffer<int> outputBuffer : register(u0);

[numthreads(4, 1, 1)]
void computeMain(uint3 dispatchThreadID : SV_DispatchThreadID)
{
	uint tid = dispatchThreadID.x;
	int inVal = outputBuffer[tid];
	int outVal = test(inVal);
	outputBuffer[tid] = outVal;
}
