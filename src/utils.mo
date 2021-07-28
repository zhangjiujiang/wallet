import Buffer "mo:base/Buffer";
import Array "mo:base/Array";

module {
    public func filter<T>(xs:[var T] , t : T,f:(T,T)->Bool) : [var T]{
        let ys : Buffer.Buffer<T> = Buffer.Buffer(xs.size());
        label l for (x in xs.vals()) {
            if(f(x,t)){
                continue l;
            };
            ys.add(x);
        };
        return ys.toVarArray();
    };
}