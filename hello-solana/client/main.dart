import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

void main() async {
  final conn = RpcClient("https://api.devnet.solana.com");
  final file1 = File(
      './dist/program/hello_solana-keypair.json');
  final jsonContent1 = await file1.readAsString();
  final List<int> secretKey1 = List<int>.from(json.decode(jsonContent1));
  final privateKey1 = Uint8List.fromList(secretKey1.sublist(0, 32));

  final Ed25519HDKeyPair keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
    privateKey: Uint8List.fromList(privateKey1),
  );

  final programId = keyPair.publicKey;

  // For using the existing account if made
  // final file2 = File(
  //     './client/account-keypair.json');
  // final jsonContent2 = await file2.readAsString();
  // final List<int> secretKey2 = List<int>.from(json.decode(jsonContent2));
  // final privateKey2 = Uint8List.fromList(secretKey2.sublist(0, 32));

  // final Ed25519HDKeyPair triggerKeypair =
  //     await Ed25519HDKeyPair.fromPrivateKeyBytes(privateKey: privateKey2);

  final Ed25519HDKeyPair triggerKeypair = await Ed25519HDKeyPair.random();
  final airdropreq = await conn.requestAirdrop(
      triggerKeypair.publicKey.toBase58(), lamportsPerSol);

  bool confirmed = false;
  for (int i = 0; i < 10; i++) {
    final statuses = await conn.getSignatureStatuses([airdropreq]);
    final status = statuses.value[0];

    if (status != null &&
        (status.confirmationStatus == Commitment.confirmed ||
            status.confirmationStatus == Commitment.finalized)) {
      confirmed = true;
      break;
    }

    print('Waiting for confirmation...');
    await Future.delayed(Duration(seconds: 1));
  }

  if (confirmed) {
    print('Airdrop confirmed!');
  } else {
    print('Airdrop not confirmed yet.');
  }

  print("Pinging program -- ${programId.toBase58()}");
  final instruction = Instruction(
      programId: programId,
      accounts: [
        AccountMeta(
            pubKey: triggerKeypair.publicKey,
            isWriteable: true,
            isSigner: false)
      ],
      data: ByteArray.u8(0));

  final transaction = Message.only(instruction);

  await conn.signAndSendTransaction(transaction, [triggerKeypair]);
}
