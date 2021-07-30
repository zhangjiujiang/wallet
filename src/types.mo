import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Float "mo:base/Float";
import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
module {

    public type WalletInfo = {
        walletName : Text;
        walletpass : Text;
    };

    public type TokenInit = {
        logo : [Nat8];
        name : Text;
        symbol : Text;
        decimal : Nat;
        totalSupply : Float;
        transferFee : Float;
    };

    public type TokenInfo = {
        symbol : Text;
        name : Text;
        owner : Principal;
    };
    
    public type WalletTokenInfo = {
        logo : [Nat8];
        symbol : Text;
        name : Text;
        balance : Float;
        price : Float;
    };
    
    public type TokenInfo_tokenList = {
        time : Time.Time;
        symbol : Text;
        name : Text;
        totalSupply : Float;
    };
    public type TokenDetails = {
        mintTime : Time.Time;
        symbol : Text;
        name : Text;
        totalSupply : Float;
        decimal : Nat;
        transferFee : Float;
        holders : Nat;
        mintAccount : Text;
    };

    public type OpType = {
        #transfer;
        #mintToken;
        #claim;
    };

    public type Record = {
        amount : Float;
        fee : Float;
        tsType : OpType;
        time : Time.Time;
        from : Principal;
        to : Principal;
        hash : Nat;
    };

    public type RecordType = {
        #token : (Text);
        #index : (Nat);
        #wallet;
        #all;
    };

    public type TokenActor = actor {
        tokenDetail : () -> async TokenDetails;
        walletTokenInfo : (who : Principal) -> async WalletTokenInfo;
        addUserToken : ( who : Principal) -> async Bool;
        delUserToken : ( who : Principal) -> async Bool;
        transfer : (from : Principal , to : Principal , value : Float) -> async Bool;
        claim : (to : Principal , value : Float) -> async Bool;
    };
}