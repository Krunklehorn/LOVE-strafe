Base = Stache.privatize(class("Base"))

function Base:__index(key, subverted)
	if class.isClass(self) and not subverted then
		return self.__index(self, key, true) end

	local slf = rawget(self, "private")
	local context = self

	while context do
		local cntxt = rawget(context, "private")
		local class = rawget(context, "class")
		local cls = class and rawget(class, "private")
		local construct = rawget(cntxt, "construct") or (class and rawget(cls, "construct")) or NULL_FUNC
		local result = cntxt[key] or rawget(context, key) or (class and (cls[key] or rawget(class, key)))

		if result then
			return result
		else
			result = construct(self, key)
			if result then
				slf[key] = result
				return slf[key]
			end
		end

		context = context ~= Base and rawget(context, "super")
	end

	return nil
end

function Base:__newindex(key, value, subverted)
	if class.isClass(self) and not subverted then
		return self.__newindex(self, key, value, true) end

	local slf = rawget(self, "private")
	local context = self
	local result = nil

	while context and not result do
		local cntxt = rawget(context, "private")
		local class = rawget(context, "class")
		local cls = class and rawget(class, "private")
		local assign = rawget(cntxt, "assign") or (class and rawget(cls, "assign")) or NULL_FUNC

		result = assign(self, key, value)
		context = context ~= Base and rawget(context, "super")
	end

	slf[key] = result or value
end

function Base:checkSet(key, value, query, nillable, copy)
	local thisClass = class.isClass(self) and self or self.class

	if value == nil and nillable == true then
		return
	else
		if query == "number" or query == "string" or query == "boolean" or query == "function" then
			if type(value) ~= query then
				Stache.formatError("Attempted to set '%s' key of class '%s' to a value that isn't a %s: %q", key, thisClass, query, value)
			end
		elseif query == "indexable" then
			if type(value) ~= "table" and type(value) ~= "userdata" then
				Stache.formatError("Attempted to set '%s' key of class '%s' to a value that isn't a table or userdata: %q", key, thisClass, value)
			end
		elseif query == "vector" then
			if not vec2.isVector(value) then
				Stache.formatError("Attempted to set '%s' key of class '%s' to a value that isn't a vector: %q", key, thisClass, value)
			end

			copy = true
		elseif query == "scalar/vector" then
			if type(value) ~= "number" and not vec2.isVector(value) then
				Stache.formatError("Attempted to set '%s' key of class '%s' to a value that isn't a scalar or a vector: %q", key, thisClass, value)
			end

			copy = true
		elseif query == "asset" then
			if type(value) ~= "string" and type(value) ~= "table" and type(value) ~= "userdata" then
				Stache.formatError("Attempted to set '%s' key of class '%s' to a value that isn't a string, table or userdata: %q", key, thisClass, value)
			end
		elseif query == "class" then
			if not class.isClass(value) then
				Stache.formatError("Attempted to set '%s' key of class '%s' to a value that isn't a class: %q", key, thisClass, value)
			end
		elseif query == "instance" then
			if not class.isInstance(value) then
				Stache.formatError("Attempted to set '%s' key of class '%s' to a value that isn't an instance: %q", key, thisClass, value)
			end
		elseif query == "index/reference" then
			if type(value) ~= "number" and not class.isInstance(value) then
				Stache.formatError("Attempted to set '%s' key of class '%s' to a value that isn't an index or instance: %q", key, thisClass, value)
			end
		elseif class.isClass(query) or class.isClass(instance) then
			query = class.isClass(query) and query or query.class

			if not value:instanceOf(query) then
				Stache.formatError("Attempted to set '%s' key of class '%s' to a value that isn't of type '%s': %q", key, thisClass, query.name, value)
			end
		else
			Stache.formatError("self:checkSet() called with a 'query' argument that hasn't been setup for type-checking yet: %q", query)
		end
	end

	return copy and Stache.copy(value) or value
end

function Base:readOnly(key, queries)
	Stache.checkArg("key", key, "string", "readOnly")
	Stache.checkArg("queries", queries, "indexable", "readOnly")

	local class = class.isClass(self) and self or self.class

	for _, query in ipairs(Stache.exclude) do
		if key == query then
			Stache.formatError("Attempted to set a key of class '%s' that is read-only: %q", class, key) end
	end

	for _, query in ipairs(queries) do
		if key == query then
			Stache.formatError("Attempted to set a key of class '%s' that is read-only: %q", class, key) end
	end
end

function Base:init(data)
	if data then
		for k, v in pairs(data) do
			self[k] = Stache.copy(v) end
	end
end
