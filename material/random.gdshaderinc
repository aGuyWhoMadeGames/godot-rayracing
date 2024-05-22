uint NextRandom(inout uint state)
{
	state = state * 747796405U + 2891336453U;
	uint result = ((state >> ((state >> 28U) + 4U)) ^ state) * 277803737U;
	result = (result >> 22U) ^ result;
	return result;
}

float RandomValue(inout uint state)
{
	return float(NextRandom(state)) / 4294967295.0; // 2^32 - 1
}

// Random value in normal distribution (with mean=0 and sd=1)
float RandomValueNormalDistribution(inout uint state)
{
	// Thanks to https://stackoverflow.com/a/6178290
	float theta = 2.0 * 3.1415926 * RandomValue(state);
	float rho = sqrt(-2.0 * log(RandomValue(state)));
	return rho * cos(theta);
}

// Calculate a random direction
vec3 RandomDirection(inout uint state)
{
	// Thanks to https://math.stackexchange.com/a/1585996
	float x = RandomValueNormalDistribution(state);
	float y = RandomValueNormalDistribution(state);
	float z = RandomValueNormalDistribution(state);
	return normalize(vec3(x, y, z));
}

vec2 RandomPointInCircle(inout uint rngState)
{
	float angle = RandomValue(rngState) * 2.0 * PI;
	vec2 pointOnCircle = vec2(cos(angle), sin(angle));
	return pointOnCircle * sqrt(RandomValue(rngState));
}

