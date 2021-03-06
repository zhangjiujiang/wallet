import Principal "mo:base/Principal";
import Types "../types";
import Float "mo:base/Float";
import Record "canister:record";
import Time "mo:base/Time";
import HashMap "mo:base/HashMap";
import Nat8 "mo:base/Nat8";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Error "mo:base/Error";
import Utils "../utils";
import Array "mo:base/Array";
import Debug "mo:base/Debug";

shared(msg) actor class Token(logo_ : [Nat8],name_ : Text,symbol_ : Text,decimal_ : Nat, totalSupply_ : Float ,transferFee_ : Float ,owner_ : Principal)=this{
    
    private stable var _logo : [Nat8] = logo_;
    private stable var _name : Text = name_;
    private stable var _symbol : Text = symbol_;
    private stable var _decimal : Nat = decimal_;
    private stable var _totalSupply : Float = totalSupply_;
    private stable var _transferFee : Float = transferFee_;
    private stable var _owner : Principal = owner_;
    private stable var _time : Time.Time = Time.now();
    private var balances = HashMap.HashMap<Principal,Float>(0,Principal.equal,Principal.hash);
    balances.put(_owner,_totalSupply);
    
    private stable var holders : [var Principal] = [var];
    holders := Array.thaw(Array.make(_owner));

    public func getCanisterAddress() : async Text{
        Debug.print("token-------getCanisterAddress:" # _symbol);
        Principal.toText(Principal.fromActor(this));
    };

    public shared(msg) func getBalance(who : Principal) : async Float {
        Debug.print("token-------getBalance: who"  #Principal.toText(who) );
        _balanceof(who);
    };

    private func _balanceof(who : Principal) : Float {
        switch(balances.get(who)){
            case (?balance) { return balance};
            case (_) {return 0};
        }
    };

    type TokenDetails = Types.TokenDetails;

    public func tokenDetail() : async TokenDetails {
        Debug.print("token-------tokenDetail");
        return {
            mintTime = _time;
            symbol = _symbol;
            name = _name;
            totalSupply = _totalSupply;
            decimal = _decimal;
            transferFee = _transferFee;
            holders = holders.size();
            mintAccount = Principal.toText(_owner);
        }
    };

    type WalletTokenInfo = Types.WalletTokenInfo;

    public func walletTokenInfo(who : Principal) : async WalletTokenInfo{
        Debug.print("token-------walletTokenInfo:" # Principal.toText(who));
        return {
            logo = _logo;
            symbol = _symbol;
            name  = _name;
            balance = _balanceof(who);
            price = 0.00;
        }
    };

    public func addUserToken(who : Principal) : async Bool{
        Debug.print("token-------addUserToken: who = "  # Principal.toText(who));
        holders := Array.thaw(Array.append(Array.freeze(holders), Array.make(who)));
        return true;
    };

    public func delUserToken(who : Principal) : async Bool{
        Debug.print("token-------delUserToken: who = "  # Principal.toText(who));
        holders := Utils.filter<Principal>(holders,who,Principal.equal);
        return true;
    };

    

    public func claim(to : Principal,value : Float) : async Bool{
        Debug.print("token-------claim: from=" # Principal.toText(_owner) # ",to=" # Principal.toText(to) # ",value=" # Float.toText(value));
        if(_balanceof(_owner) < value){
            throw Error.reject("owner balance not enough!");
            // return false;
        };
        _transfer(_owner,to,value);
        await Record.addRecord(_symbol,value,0,#claim,Time.now(),_owner,to);
        return true;
    };

    public func transfer(from : Principal, to : Principal, value : Float) : async Bool {
        Debug.print("token-------transfer: from=" # Principal.toText(from) # ",to=" # Principal.toText(to) # ",value=" # Float.toText(value));
        assert(from == _owner);
        if(value < _transferFee){
            // throw Error.reject("transfer value need more than transferFee");
            return false;
        };
        if(_balanceof(from) < value + _transferFee){
            // throw Error.reject("balance not enough,plz claim");
            return false;
        };
        _addTransferFee(from);
        _transfer(from,to,value);
        await Record.addRecord(_symbol,value,_transferFee,#transfer,Time.now(),from,to);
        return true;
    };

    private func _transfer(from : Principal ,to : Principal,value : Float){
        let from_balance = _balanceof(from);
        let from_balance_new = from_balance - value;
        balances.put(from,from_balance_new);
        let to_balance = _balanceof(to);
        let to_balance_new = to_balance + value;
        balances.put(to,to_balance_new);
    };

    private func _addTransferFee(from : Principal) {
        _transfer(from,_owner,_transferFee);
    };
}