-- http://www.ryanjuckett.com/programming/damped-springs/

local EPSILON = 0.0001;

local exp = math.exp;
local cos = math.cos;
local sin = math.sin;
local sqrt = math.sqrt;

local spring = {};
local spring_mt = {__index = spring};

function spring.new(p0, v0, target, angularFrequency, dampingRatio)
	local self = {};
	self.p = p0;
	self.v = v0;
	self.target = target;
	self.angularFrequency = angularFrequency or 10;
	self.dampingRatio = dampingRatio or 1;
	return setmetatable(self, spring_mt);
end

function spring:update(dt)
	local aF = self.angularFrequency;
	local dR =  self.dampingRatio;
	
	if (aF < EPSILON) then return; end;
	if (dR < 0) then dR = 0; end;
	
	local epos = self.target;
	local dpos = self.p - epos;
	local dvel = self.v;
	
	if (dR > 1 + EPSILON) then
		local za = -aF * dR;
		local zb = aF * sqrt(dR*dR - 1);
		local z1 = za - zb;
		local z2 = za + zb;
		local expTerm1 = exp(z1 * dt);
		local expTerm2 = exp(z2 * dt);
		
		local c1 = (dvel - dpos*z2)/(-2*zb);
		local c2 = dpos - c1;
		self.p = epos + c1*expTerm1 + c2*expTerm2;
		self.v = c1*z1*expTerm1 + c2*z2*expTerm2;
	elseif (dR > 1 - EPSILON) then
		local expTerm = exp(-aF * dt);
		
		local c1 = dvel + aF*dpos;
		local c2 = dpos;
		local c3 = (c1*dt + c2)*expTerm;
		
		self.p = epos + c3;
		self.v = (c1*expTerm) - (c3*aF);
	else
		local omegaZeta = aF*dR;
		local alpha = aF*sqrt(1 - dR*dR);
		local expTerm = exp(-omegaZeta*dt);
		local cosTerm = cos(alpha*dt);
		local sinTerm = sin(alpha*dt);
		
		local c1 = dpos;
		local c2 = (dvel + omegaZeta*dpos) / alpha;
		self.p = epos + expTerm*(c1*cosTerm + c2*sinTerm);
		self.v = -expTerm*((c1*omegaZeta - c2*alpha)*cosTerm + (c1*alpha + c2*omegaZeta)*sinTerm);
	end
end

return spring;