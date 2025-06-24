// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ImovelAdmin is Ownable {
    struct Imovel {
        address proprietario;
        address tokenAddress;
    }

    mapping(uint256 => Imovel) public imoveis;
    uint256 public totalImoveis;

    event ImovelCadastrado(uint256 indexed id, address proprietario, address tokenAddress);

    constructor(address initialOwner) Ownable(initialOwner) {}

    function cadastrarImovel(
        string memory name,
        string memory symbol,
        uint256 supply,
        uint256 tokenPrice
    ) public {
        ImovelToken novoToken = new ImovelToken(name, symbol, supply, tokenPrice, msg.sender);
        imoveis[totalImoveis] = Imovel(msg.sender, address(novoToken));
        emit ImovelCadastrado(totalImoveis, msg.sender, address(novoToken));
        totalImoveis++;
    }

    function getTokenAddress(uint256 imovelId) public view returns (address) {
        return imoveis[imovelId].tokenAddress;
    }

    function getProprietario(uint256 imovelId) public view returns (address) {
        return imoveis[imovelId].proprietario;
    }
}

contract ImovelToken is ERC20, Ownable {
    uint256 public tokenPrice;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 supply_,
        uint256 price_,
        address proprietario_
    ) ERC20(name_, symbol_) Ownable(proprietario_) {
        _mint(proprietario_, supply_ * 10 ** decimals());
        tokenPrice = price_;
    }

    function sellTokens(address to, uint256 amount) external onlyOwner {
        _transfer(owner(), to, amount * 10 ** decimals());
    }

    function buyTokens(uint256 amount) public payable {
        require(msg.value == amount * tokenPrice, "Valor ETH incorreto.");
        require(balanceOf(owner()) >= amount * 10 ** decimals(), "Proprietario sem tokens suficientes.");
        _transfer(owner(), msg.sender, amount * 10 ** decimals());
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}
}
