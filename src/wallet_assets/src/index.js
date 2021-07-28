import { Actor, HttpAgent } from '@dfinity/agent';
import { idlFactory as wallet_idl, canisterId as wallet_id } from 'dfx-generated/wallet';

const agent = new HttpAgent();
const wallet = Actor.createActor(wallet_idl, { agent, canisterId: wallet_id });

document.getElementById("clickMeBtn").addEventListener("click", async () => {
  const name = document.getElementById("name").value.toString();
  const greeting = await wallet.greet(name);

  document.getElementById("greeting").innerText = greeting;
});
