import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'api_config.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final userMessageController = TextEditingController();
  late final ChatSession chatSession;
  final GenerativeModel generativeModel =
      GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
  bool isLoading = false;
  final messageScrollController = ScrollController();

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => messageScrollController.animateTo(
        messageScrollController.position.maxScrollExtent,
        duration: const Duration(
          milliseconds: 750,
        ),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    chatSession = generativeModel.startChat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Expanded(
          child: ListView(
            controller: messageScrollController,
            padding: const EdgeInsets.all(16.0),
            children: [
              ...chatSession.history.map(
                (content) {
                  var text = content.parts
                      .whereType<TextPart>()
                      .map<String>((e) => e.text)
                      .join('');
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        content.role == 'user' ? 'User:' : 'Gemini:',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      MarkdownBody(data: text),
                      const Divider(),
                      const SizedBox(height: 10.0),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: userMessageController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter your prompt',
                  ),
                  onEditingComplete: () {
                    if (!isLoading) {
                      sendUserMessage();
                    }
                  },
                ),
              ),
              isLoading
                  ? const CircularProgressIndicator()
                  : IconButton(
                      onPressed: sendUserMessage,
                      icon: const Icon(Icons.send),
                    ),
            ],
          ),
        )
      ]),
    );
  }

  sendUserMessage() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await chatSession
          .sendMessage(Content.text(userMessageController.text));

      if (response.text == null) {
        displayError('No response from API');
      } else {
        setState(() {
          isLoading = false;
          scrollToBottom();
        });
      }
    } catch (e) {
      displayError(e.toString());
      setState(() {
        isLoading = false;
      });
    } finally {
      userMessageController.clear();
      setState(() {
        isLoading = false;
      });
    }
  }

  displayError(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
