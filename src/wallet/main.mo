import Types "../types";
import Error "mo:base/Error";
import Array "mo:base/Array";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Token "../token/main";
import Text "mo:base/Text";
import Option "mo:base/Option";
import List "mo:base/List";
import Utils "../utils";
import Debug "mo:base/Debug";
actor {
    type WalletInfo = Types.WalletInfo;
    private var wallets = HashMap.HashMap<Principal,WalletInfo>(1,Principal.equal,Principal.hash);

    public shared(msg) func register(walletInfo_ : WalletInfo) : async Principal {
        let walletId = msg.caller;
        let walletInfo = wallets.get(walletId);
        switch(walletInfo){
            case (?WalletInfo){
                throw Error.reject("you already register ,plz login in");
            };
            case _ {
                wallets.put(walletId,{
                    walletName = walletInfo_.walletName;
                    walletpass = walletInfo_.walletpass;
                });
                //给每个注册的用户添加ICST token
                ignore addToken("ICST");
                return walletId;
            };
        }
    };

    // public shared(msg) func login(walletInfo_ : WalletInfo) : async Principal {
    //     let walletId = msg.caller;
    //     let walletInfo = wallets.get(walletId);
    //     switch(walletInfo){
    //         case (?WalletInfo){
    //             if(Text.equal(walletInfo_.walletpass,walletInfo_.walletpass)){
    //                 return walletId;
    //             }else{
    //                 throw Error.reject("walletName or password incorrect!");    
    //             }
    //         };
    //         case null {
    //             throw Error.reject("walletName hasn`t register!");
    //         };
    //     }
    // };


    ///token
    type TokenInit = Types.TokenInit;
    type WalletTokenInfo = Types.WalletTokenInfo;
    type TokenDetails = Types.TokenDetails;
    type TokenActor = Types.TokenActor;

    private /**stable*/ var allSymbols : [var Text] = [var];
    private var tokenActor = HashMap.HashMap<Text,TokenActor>(0,Text.equal,Text.hash);
    private var userToken = HashMap.HashMap<Principal,List.List<Text>>(0,Principal.equal,Principal.hash);
    private var userTokenNum = HashMap.HashMap<Principal,Nat>(0,Principal.equal,Principal.hash);
    ///mint token总数限制/单人限制
    private var maxToekn : Nat = 100;
    private var maxTokenper : Nat= 1;
    //mintToken
    public shared(msg) func mintToken (tokenInit : TokenInit) : async Bool{
        if(allSymbols.size() >= maxToekn){
            throw Error.reject("Exceeds max number of tokens");
        };
        var symbol = tokenInit.symbol;
        // Cycles.add(tokenInit.totalSupply);
        var userTokenCount : Nat = 0;
        switch(userTokenNum.get(msg.caller)) {
            case (?tokenCount) {
                if(tokenCount > maxTokenper) {
                    throw Error.reject("exceeds max number of tokens per user");
                };
                userTokenCount := tokenCount;
            };
            case (_) {};
        };
        var token = await Token.Token(tokenInit.logo,tokenInit.name,tokenInit.symbol,tokenInit.decimal,tokenInit.totalSupply,tokenInit.transferFee);
        tokenActor.put(symbol,token);
        allSymbols := Array.thaw(Array.append<Text>(Array.freeze(allSymbols),Array.make<Text>(symbol)));
        if(symbol != "ICST"){
            _addUserToken(msg.caller,symbol);
        };
        userTokenNum.put(msg.caller,userTokenCount + 1);
        return true;
    };

    func _addUserToken(walletId : Principal,symbol : Text) {
        switch (userToken.get(walletId)) {
            case (?list){
                Debug.print("---------addUserToken has value");
                userToken.put(walletId,List.push(symbol,list));                
            };
            case (_) {                
                Debug.print("---------addUserToken _");
                userToken.put(walletId,List.make(symbol));
            };
        };
    };

    func delUserToken(walletId : Principal,symbol : Text){
        switch(userToken.get(walletId)){
            case (?list){
                var userTokenArray : [var Text] = List.toVarArray<Text>(list);
                userTokenArray := Utils.filter<Text>(userTokenArray,symbol,Text.equal);
                userToken.put(walletId,List.fromVarArray(userTokenArray));
            };
            case _ {};
        };
    };

    
    
    //tokenDetails
    public  func tokenDetail (symbol : Text) : async TokenDetails{
        let token  = tokenActor.get(symbol);
        let tokenDetails : TokenDetails = await Option.unwrap(token).tokenDetail(symbol);
    };

    //addToken
    public shared(msg) func addToken (symbol : Text) : async Bool {
        var token = tokenActor.get(symbol);
        let added = await Option.unwrap(token).addUserToken(symbol);
        if(added){
            _addUserToken(msg.caller,symbol);
            return true;
        };
        return false;
    };

    //delToken
    public shared(msg) func delToken (symbol : Text) : async Bool {
        var token = tokenActor.get(symbol);
        let deleted : Bool = await Option.unwrap(token).delUserToken(symbol);
        if(deleted){
            delUserToken(msg.caller,symbol);
            return true;
        };
        return false;
    };
        
    ///token list 
    public  func tokenList () : async [TokenDetails] {
        var tokenDetails : [TokenDetails] = [];
        for(symbol in allSymbols.vals()){
            let token = tokenActor.get(symbol);
            let tokenDetail = await Option.unwrap(token).tokenDetail(symbol);
            tokenDetails := Array.append<TokenDetails>(tokenDetails,[tokenDetail]);
        };
        tokenDetails;
    };

    ///wallet 页面的用户tokenlist
    public shared(msg) func walletTokenList () : async [WalletTokenInfo] {
        var walletTokenInfos : [WalletTokenInfo] = [];
        switch(userToken.get(msg.caller)) {
            case (?list){
                Debug.print("---------walletTokenList has value");
                var userTokenArray:[Text] = List.toArray<Text>(list);
                for(symbol in userTokenArray.vals()){
                    let token = tokenActor.get(symbol);
                    let walletTokenInfo = await Option.unwrap(token).walletTokenInfo();
                    walletTokenInfos := Array.append<WalletTokenInfo>(walletTokenInfos,Array.make(walletTokenInfo));
                };
            };
            case _ {
                Debug.print("---------walletTokenList null");
            };
        };
        walletTokenInfos;
    };


    ///transfer
    public shared(msg) func transfer(symbol : Text,to : Principal,value : Float, password : Text) : async Bool{
        switch(wallets.get(msg.caller)){
            case (?walletInfo){
                if(password == walletInfo.walletpass){
                    let token = tokenActor.get(symbol);
                    return await Option.unwrap(token).transfer(to,value);
                }else{
                    return false;
                };
            };
            case _ {
                return false;
            };
        }
    };

    ///claim
    public shared(msg) func claim(symbol : Text,to : Principal,value : Float, password : Text) : async Bool{
        switch(wallets.get(msg.caller)){
            case (?walletInfo){
                if(password == walletInfo.walletpass){
                    let token = tokenActor.get(symbol);
                    return await Option.unwrap(token).claim(to,value);
                }else{
                    return false;
                };
            };
            case _ {return false;};
        }
    };

};
