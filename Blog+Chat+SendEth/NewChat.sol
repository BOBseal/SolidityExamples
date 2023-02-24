
pragma solidity >=0.8.0;

contract Chat {
    struct user{
        string name;
        friend[] friendList;
        Blog[] blogList;
    }
    struct friend{
        address pubKey;
        string  name;
    }
    struct Blog {
        uint ID;
        string title;
        string content;
        uint timestamp;
        uint likes;
    }
    struct message {
        address sender;
        uint timestamp;
        string msg;
    }

    struct AllUserStruct{
        string name;
        string mailId;
        address accountAddress;
    }
    address payable owner;
     constructor() {
        owner = payable(msg.sender);
        IDCount = 1;
    }
    AllUserStruct[] getAllUsers;
    uint IDCount;
    mapping(address => user) userList;
    mapping(bytes32 => message[]) allMessages;
    mapping(bytes32 => bool) likedBlogs;

    function checkUserExists(address pubKey) public view returns (bool) {
        return bytes(userList[pubKey].name).length >0;
    }
  function likedByUser(uint blogID) internal view returns(bool) {
    bytes32 blogKey = keccak256(abi.encodePacked(msg.sender, blogID));
    return likedBlogs[blogKey];
   }

    function addBlogPost(string calldata title, string calldata content) external {
    require(checkUserExists(msg.sender), "Please Create an Account First");
    require(bytes(title).length > 0 ,"Title Cannot Be Empty");
    require(bytes(content).length>0,"Blog Cannot be Empty");
    Blog memory newBlog = Blog(IDCount,title, content , block.timestamp, 0);
    userList[msg.sender].blogList.push(newBlog);
    IDCount++;
    }

function likeBlogPost(uint blogID) external {
    require(checkUserExists(msg.sender), "Please Create an Account First");
    require(userList[msg.sender].blogList.length >= blogID, "Blog ID does not exist");
    require(likedByUser(blogID) == false, "Post already liked by user");

    Blog storage blog = userList[msg.sender].blogList[blogID-1];
    blog.likes++;

    bytes32 blogKey = keccak256(abi.encodePacked(msg.sender, blogID));
    likedBlogs[blogKey] = true;
}


    function getBlogPosts(address userAddress) external view returns (Blog[] memory) {
        require(checkUserExists(userAddress), "User Not Valid");
        return userList[userAddress].blogList;
    }


    function createAccount(string calldata name , string memory mailId) external {
        require( checkUserExists(msg.sender) == false , "User Already Exists!");
        require(bytes(name).length > 0 , "User Name Cannot Be Empty"); 
         require(keccak256(bytes(mailId)) != keccak256(bytes("")), "Email address cannot be empty");
        //add function here that checks whether email already exist in the allUserStruct array
       for (uint i = 0; i < getAllUsers.length; i++) {
        require(
            keccak256(bytes(getAllUsers[i].mailId)) != keccak256(bytes(mailId)),
            "Email address already registered"
        );
    }
        userList[msg.sender].name = name;
        getAllUsers.push(AllUserStruct(name , mailId ,msg.sender));

    }

    function getUsername (address pubKey) external view returns (string memory ){
        require( checkUserExists(pubKey), "User Not Registered!");
        return userList[pubKey].name;
    }

    function checkAlreadyFriends(address pubKey1, address pubKey2 ) internal view returns(bool){
        if(userList[pubKey1].friendList.length > userList[pubKey2].friendList.length){
            address tmp = pubKey1;
            pubKey1 = pubKey2;
            pubKey2 = tmp;
        }

        for(uint256 i = 0; i<userList[pubKey1].friendList.length; i++ ){
            if (userList[pubKey1].friendList[i].pubKey == pubKey2) return true;
        }
        return false;
    } 

    function addFriend(address friend_key, string calldata name) external {
        require(checkUserExists(msg.sender), "Create an Account");
        require(checkUserExists(friend_key), "User Not Registered");
        require(msg.sender != friend_key , "You cannot add yourself!");
        require(checkAlreadyFriends(msg.sender, friend_key)== false,"Already Addes User!");

        _addFriend(msg.sender, friend_key, name);
        _addFriend(friend_key, msg.sender, userList[msg.sender].name);

    }

    function _addFriend(address me , address friend_key , string memory name) internal {
        friend memory newFriend = friend(friend_key, name);
        userList[me].friendList.push(newFriend);
    }

    function getMyFriendList()external view returns(friend[] memory){
        return userList[msg.sender].friendList;
    }

    function _getChatCode(address pubKey1, address pubKey2 ) internal pure returns(bytes32){
        if(pubKey1 < pubKey2){
            return keccak256(abi.encodePacked(pubKey1, pubKey2));
        } else return keccak256(abi.encodePacked(pubKey2, pubKey1));
    }

    function sendMessage(address friend_key, string calldata _msg) external {
        require(checkUserExists(msg.sender), "Please Create an Account First");
        require(checkUserExists(friend_key), "User Not Valid");
        require(checkAlreadyFriends(msg.sender, friend_key), "You're not friends with this User! ");
    
        bytes32 chatCode = _getChatCode(msg.sender, friend_key);
        message memory newMsg = message(msg.sender, block.timestamp, _msg);
        allMessages[chatCode].push(newMsg);
    }

    function readMessage( address friend_key) external view returns(message[] memory){
        bytes32 chatCode = _getChatCode(msg.sender, friend_key);
        return allMessages[chatCode];

    }

    function getAllAppUsers() public view returns ( AllUserStruct[] memory ){
        return getAllUsers;
    }
}
//to-do later
//add donation function
//add a task list for users
//add uri storage for ipfs functionality in Message , Blog 
// add decentralised storage uri save for users
