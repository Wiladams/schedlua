functor
=======

	A functor is a function that can stand in for another function.
	It is somewhat of an object because it retains a certain amount 
	of state.  In this case, it retains the target object, if there is 
	any.

	This is fairly useful when you need to call a function on an object
	at a later time.

	Normally, if the object is constructed thus:

	function obj.func1(self, params)
	end

	You would call the function thus:
	objinstance:func1(params)

	which is really
	obj.func1(objinstance, params)

	The object instance is passed into the function as the 'self' parameter
	before the other parameters.

	This is easy enough, but when you want to store a reference to the function
	to be called in a table?  It's easy enough to store 'obj.func1', but what
	about the instance value?  We must retain the 'objinstance' somewhere.

	This is where the Functor comes in.  It will store both the object instance 
	(target, if there is one) and the function reference for later execution.

	You can use it like this:

	funcs = {
		routine1 = Functor(obj.func1, someobj);
		routine2 = Functor(obj.func1, someobj2);
		routine3 = Functor(obj.func2, someobj);
	}
	
	Then use it as:
	  funcs.routine1(params);
	  funcs.routine3(params);