import Types "../types";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Float "mo:base/Float";
import Array "mo:base/Array";
import Time "mo:base/Time";

actor {
    type Record = Types.Record;
    type RecordType = Types.RecordType;
    type OpType = Types.OpType;
    ///总记录
    private var allRecord : [var Record] = [var];
    
    ///token记录
    private var tokenRecord = HashMap.HashMap<Text,[var Record]>(1,Text.equal,Text.hash);

    ///wallet记录
    private var walletRecord =  HashMap.HashMap<Principal,[var Record]>(1,Principal.equal,Principal.hash);

    public func addRecord(
        symbol : Text,
        amount : Float,
        fee : Float,
        tsType : OpType,
        time : Time.Time,
        from : Principal,
        to : Principal) : async (){
        let index = allRecord.size();
        let record : Record = {
            amount = amount;
            fee = fee;
            tsType = tsType;
            time = time;
            from = from;
            to = to;
            hash = index;
        };
        saveRecord(symbol,record);
    };

    private func saveRecord(symbol : Text, record : Record) {

        allRecord := Array.thaw(Array.append(Array.freeze(allRecord),Array.make(record)));

        switch(tokenRecord.get(symbol)){
            case (?records){
                var record_new = Array.thaw<Record>(Array.append(Array.freeze(records),Array.make(record)));
                tokenRecord.put(symbol,record_new);
            };
            case _{
                tokenRecord.put(symbol,Array.thaw(Array.make(record)));
            };
        };

        let from = record.from;
        switch(walletRecord.get(from)){
            case(?records){
                var record_new = Array.thaw<Record>(Array.append(Array.freeze(records),Array.make(record)));
                walletRecord.put(from,record_new);
            };
            case (null){
                walletRecord.put(from,Array.thaw(Array.make(record)));
            };
        };

        let to = record.to;
        switch(walletRecord.get(to)){
            case(?records){
                var record_new = Array.thaw<Record>(Array.append(Array.freeze(records),Array.make(record)));
                walletRecord.put(to,record_new);
            };
            case (null){
                walletRecord.put(to,Array.thaw(Array.make(record)));
            };
        };
    };

    

    public shared(msg) func getRecord(recordType : RecordType) : async [Record]{
        switch(recordType){
            case (#token(symbol)) {
                switch(tokenRecord.get(symbol)){
                    case (?records){return Array.freeze(records)};
                    case _ {return []};
                };
            };
            case (#wallet) {
                switch(walletRecord.get(msg.caller)){
                    case (?records){return Array.freeze(records)};
                    case _ {[]};
                };
            };
            case (#index(index)){
                return Array.make<Record>(allRecord[index-1]);
            };
            case (#all) {
                return Array.freeze(allRecord);
            };
        }
    };
}