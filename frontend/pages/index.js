import { ConnectWallet, useContract } from "@thirdweb-dev/react";
import { Web3Button } from "@thirdweb-dev/react";
import styles from "../styles/Home.module.css";
import { useEffect, useState } from "react";

const player2 = "0x25cb2E5889Ff2ee10398F8413f83217c59DbC1A0";
const contract_address = "0x25cb2E5889Ff2ee10398F8413f83217c59DbC1A0";

const convertTo2DArray = (str) => {
  const rows = 6;
  const cols = 7;
  let arr = [];

  for (let i = 0; i < rows; i++) {
    let rowArr = [];
    for (let j = 0; j < cols; j++) {
      rowArr.push(parseInt(str[i * cols + j], 10)); // Convert the character to an integer
    }
    arr.push(rowArr);
  }

  return arr;
};

export default function Home() {
  const [gameState, setGameState] = useState({
    currentPlayer: 0,
    gameActive: false,
    gameBoard: Array(6)
      .fill(null)
      .map(() => Array(7).fill(0)),
    playersInGame: [],
    totalWager: null,
    winnerAddress: "",
  });
  const { contract } = useContract(contract_address);
  const [inputAddress, setInputAddress] = useState("");

  useEffect(() => {
    if (contract) {
      const fetchGameState = async () => {
        const state = await contract.call("getGame", ["2"]);
        setGameState(state);
      };

      fetchGameState();
    }
  }, [contract]);

  const startGameWithInput = async () => {
    if (contract) {
      try {
        await contract.call("startGame", [inputAddress]);
        // Refresh the game state or handle other necessary updates
      } catch (error) {
        console.error("Error starting the game:", error);
      }
    }
  };

  return (
    <main className={styles.main}>
      <div className={styles.container}>
        <div className={styles.header}>
          <h1 className={styles.title}>
            <span className={styles.gradientText0}>Connect4 With Wager</span>
          </h1>

          <div className={styles.connect}>
            <ConnectWallet
              dropdownPosition={{
                side: "bottom",
                align: "center",
              }}
            />
          </div>
          <div className="flex items-center space-x-4 mt-4">
            <Web3Button
              contractAddress={contract_address}
              action={async (contract) => {
                try {
                  await contract.call("startGame", [inputAddress]);
                  // Refresh the game state or handle other necessary updates
                } catch (error) {
                  console.error("Error starting the game:", error);
                }
              }}
            >
              Start Game
            </Web3Button>{" "}
            :{" "}
            <input
              type="text"
              value={inputAddress}
              onChange={(e) => setInputAddress(e.target.value)}
              placeholder="Enter player2 address"
              className="tw-web3button css-1fii1tk w-96 px-4 py-2 font-mono"
            />
          </div>
        </div>
        <br />

        <div className={styles.board}>
          {gameState &&
          gameState.gameBoard &&
          gameState.gameBoard.length > 0 ? (
            gameState.gameBoard.map((row, rowIndex) => (
              <div key={rowIndex} className={styles.row}>
                {row.map((cell, cellIndex) => (
                  <div
                    key={cellIndex}
                    className={`${styles.cell} ${
                      cell === 0
                        ? styles.empty
                        : cell === 1
                        ? styles.player1
                        : styles.player2
                    }`}
                  ></div>
                ))}
              </div>
            ))
          ) : (
            <p>No game board data available.</p>
          )}
        </div>
      </div>
    </main>
  );
}
