// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ImovelToken is ERC1155, Ownable {

    // ... (struct ImovelInfo, mapping, event, constructor - tudo igual a antes) ...
    struct ImovelInfo {
        string nome;
        string enderecoCompleto;
        string urlImagem;
        string inscricaoImobiliaria;
        string matricula;
        string oficio;
        uint256 valorTotal; // Valor em Wei
        address proprietarioOriginal;
        uint256 totalDeTokens;
        bool tokenizado;
    }
    mapping(uint256 => ImovelInfo) public imoveis;
    uint256 private _nextTokenId;
    event ImovelTokenizado(
        uint256 indexed tokenId,
        address indexed proprietarioOriginal,
        string nome,
        uint256 quantidadeTokens
    );
    constructor() ERC1155("") Ownable(msg.sender) {
        _nextTokenId = 1;
    }
    function tokenizarImovel(
        // ... (todos os parâmetros de antes) ...
        address proprietarioCarteira, uint256 quantidadeTokens, uint256 valorTotalEmEther,
        string memory nome, string memory enderecoCompleto, string memory urlImagem,
        string memory inscricao, string memory matricula, string memory oficio
    ) public onlyOwner {
        // ... (lógica igual a antes) ...
        require(proprietarioCarteira != address(0), "Carteira do proprietario e invalida.");
        require(quantidadeTokens > 0, "A quantidade de tokens deve ser maior que 1.");
        uint256 tokenId = _nextTokenId++;
        imoveis[tokenId] = ImovelInfo({
            nome: nome, enderecoCompleto: enderecoCompleto, urlImagem: urlImagem,
            inscricaoImobiliaria: inscricao, matricula: matricula, oficio: oficio,
            valorTotal: valorTotalEmEther * 1 ether, proprietarioOriginal: proprietarioCarteira,
            totalDeTokens: quantidadeTokens, tokenizado: true
        });
        _mint(proprietarioCarteira, tokenId, quantidadeTokens, "");
        emit ImovelTokenizado(tokenId, proprietarioCarteira, nome, quantidadeTokens);
    }
    // ... (função getImovelInfo e uri - iguais a antes) ...
    function getImovelInfo(uint256 tokenId) public view returns (ImovelInfo memory) {
        require(imoveis[tokenId].tokenizado, "Imovel com este ID nao existe.");
        return imoveis[tokenId];
    }
    function uri(uint256) public view virtual override returns (string memory) {
        return "";
    }


    // --- NOVA FUNÇÃO DE COMPRA ---

    /**
     * @notice Permite que qualquer pessoa compre tokens de um imóvel diretamente do proprietário original.
     * @dev A função é 'payable', ou seja, pode receber Ether. O proprietário original (vendedor)
     * deve ter previamente aprovado este contrato para movimentar seus tokens via setApprovalForAll.
     * @param tokenId O ID do imóvel cujos tokens estão sendo comprados.
     * @param quantidade O número de tokens a serem comprados.
     */
    function comprarTokens(uint256 tokenId, uint256 quantidade) public payable {
        ImovelInfo storage imovel = imoveis[tokenId];
        require(imovel.tokenizado, "Este imovel nao existe ou nao foi tokenizado.");
        require(quantidade > 0, "A quantidade de compra deve ser maior que zero.");

        address vendedor = imovel.proprietarioOriginal;
        address comprador = msg.sender; // msg.sender aqui é a Carteira 3

        // Calcula o preço por token e o custo total da compra
        uint256 precoPorToken = imovel.valorTotal / imovel.totalDeTokens;
        uint256 custoTotal = precoPorToken * quantidade;

        // Verifica se o comprador enviou Ether suficiente
        require(msg.value >= custoTotal, "Valor em Ether enviado e insuficiente para a compra.");

        // Verifica se o vendedor tem tokens suficientes para vender
        require(balanceOf(vendedor, tokenId) >= quantidade, "O vendedor nao possui tokens suficientes.");

        // A MÁGICA ACONTECE AQUI:
        // O contrato (agindo como corretor) transfere os tokens da carteira do vendedor
        // para a carteira do comprador. Isso SÓ FUNCIONA se o vendedor deu a permissão.
        safeTransferFrom(vendedor, comprador, tokenId, quantidade, "");

        // O contrato transfere o dinheiro (Ether) recebido para o vendedor.
        payable(vendedor).transfer(custoTotal);

        // Se o comprador enviou dinheiro a mais, o contrato devolve o troco.
        if (msg.value > custoTotal) {
            payable(comprador).transfer(msg.value - custoTotal);
        }
    }
}