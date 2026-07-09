---
title: Writing Style
parent: Knowledge
permalink: /knowledge/writing-style/
nav_order: 1
---

# Writing Style

Nicolas's voice across written communication. The **voice** (tone, structure, posture) is the same everywhere; only the **formatting** changes per channel.

## Universal voice

Apply these to every drafted message (Slack, email, Notion, PR description, status update).

- **Open with a narrative frame, not a headline.** Combine the topic AND your feeling about it in the first sentence. "j'ai bien avancé sur X qui est en fait une belle pelote de laine 🧵" tells the reader it was harder than expected without complaining. Avoid clinical openings like "PR ready for review".
- **Share reasoning, not just conclusions.** When you made a choice, name the alternative and assume the opinion: "j'ai choisi X parce que [raison], il y'avait d'autres solutions". Open to debate without inviting it.
- **Narrate the journey.** Show before/after: "Ca fait pas mal de choses, mais maintenant le plan est propre." Don't just describe the current state — make the effort visible.
- **End vulnerable, not triumphant.** Surface the unglamorous workaround or remaining risk instead of hiding it. "Peut-être qu'il va nous falloir un autre refresh manuel 😅". Builds trust.
- **Direct first sentence, no preamble.** Skip "Je me permets de...", "Je vous écris pour...", "I wanted to reach out about...". Get to the point.
- **French parlé but precise.** "Du coup", "y'avait", "ça fait pas mal" are fine in casual contexts. Casual ≠ sloppy — proper nouns stay correctly capitalized (Cloudflare, Terraform, DNS, GitHub).
- **Short and warm closings.** "Merci !", "Belle journée,", "À bientôt,". Never "Cordialement" or "Veuillez agréer".
- **Émoji rare et sémantique.** 🧵 for entanglement, 😅 for self-deprecation, "!" for friendly emphasis. Never decorative.
- **Length matches medium.** Slack status update: 4-6 short paragraphs. Slack DM: 1-2 lines. Email: 2-5 sentences max.

## Channel-specific formatting

### Slack

Use the full Slack formatting palette — don't default to plain text.

| Element | Usage |
|---|---|
| `` `code` `` | Technical identifiers: tool names, file paths, commands, domains. Ex: `` `terraform` ``, `` `app.example.fr` ``, `` `terraform plan/apply` ``. |
| `*italic*` | Product/proper nouns once in context: *Cloudflare*, *sub-issue GitHub*. |
| `**bold**` | Key state or action words: **à review**, **C'est ce qui activera le certificat SSL**. |
| `> quote` | Final tentative/self-deprecating aside. Sets it apart visually as "thinking out loud". |
| Native bullets | Parallel-action lists. Format: `[action] -> issue #NNNN` or `-> pr #NNNN`. |
| Plain `#NNNN` | GitHub refs. Slack auto-unfurls same-org links — no markdown links needed. |

**Typical structure for a multi-track status update:**

1. Opening paragraph with narrative frame + emotional signal (1-2 sentences)
2. Reasoning paragraph explaining the high-level choice (1-2 sentences)
3. Macro context line ("la macro issue est #NNNN") then bullets decomposing the work
4. Wrap paragraph with before/after framing ("maintenant le plan est propre")
5. Quote-block aside with humble caveat or remaining risk

### Email

More formal than Slack. Vouvoiement simple, no emoji in body.

- **Greeting**: "Bonjour," or "Bonsoir," (standalone). "Bonjour/Bonsoir [Prénom]" or "Mme/M. [Nom]" only when Nicolas knows the person.
- **Body**: Direct, to the point in the first sentence. The universal-voice principles still apply.
- **Opening**: a complete sentence with a verb — "Voici notre retour sur…", not a nominal fragment ("Le retour promis sur…"). "Notre/nous" when writing for Qraft.
- **Closing**: Short and warm — "Merci !", "Belle journée,", "Merci et bonne journée,", "À bientôt,".
- **Sign-off**: Just "Nicolas" (first name only). Gmail appends the signature automatically — never inline contact info.
- **Tone**: Natural, warm, concise. Vouvoiement simple. Uses "!" for friendly emphasis.
- **Length**: 2-5 sentences max. Numbered lists for multiple questions.
- **Lists**: real HTML bullets (`--body-html` with `<ul><li>` when drafting via gog), compact — no blank lines between items. When a bullet opens with a short thesis ("Le point délicat : le devoir de conseil."), set that lead-in in *italics* (`<i>`), then the detail in plain text.
- **Links**: embedded as clickable hyperlinks in the HTML body, never bare URLs in plain text.
- **Never**: "Veuillez agréer", "Cordialement", "Je me permets de...", "N'hésitez pas à me contacter", long preambles.

### Notion / long-form docs

Covers blog posts (external) and technical write-ups (internal) alike — same register. The universal-voice principles still apply; what follows is the long-form layer on top.

**The shape that works:**

- **Short opener, no preamble.** For change/migration posts, a two-line `Avant : … / Après : …` followed by a single line pointing to the macro issue or PR is enough. For other posts, one or two short paragraphs stating the goal. No "Dans cet article…", no "Format : 10 minutes…".
- **Plain numbered sections** (`## 1. …`, `## 2. …`). Each section ends with relevant refs on a single trailing line: `→ #1212, PR #1208.`
- **At least one real code block per section** — HCL, YAML, bash, kubectl/curl verification, etc. Snippets from the actual code/PRs/scripts, not paraphrased examples.
- **Inline doc links throughout** — provider docs, CLI repos, RFC pages, internal Slite docs. A consolidated "Tous les liens" / "All links" section at the end is fine but doesn't replace inline links.
- **Honest tail section** (`## Ce qui reste` / `## What's still pending`) listing limitations and open items. No triumphant wrap-up after it.

**Avoid in long-form:**

- Clickbait titles or "X will change everything" framings.
- Opening `🎯` pitch callouts or closing `💬` punchline callouts — they read as overwritten.
- Grandiose constructions: "L'équation, c'est :", "C'est ce qui ferme la boucle", "déterministe et autonome", "tuer le rituel", "Si X demande Y, elle est incomplète".
- Acte 1 / Acte 2 / Acte 3 structure. Two existing TBMAs use it, but it doesn't generalize — copying it lands as theatrical.
- Long preambles, multi-paragraph framing, restated stakes.
- Tool comparison tables unless the comparison itself is the point of the article.
- Buzzwords: "game-changer", "revolutionize", "leverage", "unlock".

The universal voice (direct first sentence, share reasoning, vulnerable closing, semantic emoji) still applies — just without the Slack-style narrative arc.

### LinkedIn / X (posts réseaux)

Le ton sobre prime — pas de codes "influenceur LinkedIn". Feedback direct de Nicolas (2026-07-02) sur les premiers posts programmés, complété par ses révisions manuelles des posts Rails/streaming et WhatWouldClaudeUse (2026-07-06) — les exemples ci-dessous en sont tirés.

- **Pas de tournures à punchline** : "Le problème n'était pas X, c'est Y", "Le twist :", hooks d'accroche, listes fléchées `→`. Les "grandiose constructions" interdites en long-form le sont aussi ici.
- **L'angle, c'est la recette réutilisable, pas l'inventaire interne.** Un post technique répond à "comment faire X" pour le lecteur (l'architecture, les briques, le détail qui surprend). Les spécificités de nos implémentations — laquelle est incohérente, laquelle écrase vs concatène — sont des détails internes qui n'intéressent personne.
- **Personnel = expérience concrète, pas récit du chantier.** "Ce qu'on a utilisé et comment" (les tools, les tables, le pattern), pas "c'était un grand ménage / on a choisi d'unifier". Le vécu passe par les choix techniques montrés, pas par la narration de l'effort.
- **Honnêteté factuelle, même défavorable.** Ne jamais embellir le verdict de Nicolas sur son propre travail — si un résultat était illisible ou décevant, le post le dit tel quel. L'honnêteté est l'angle, pas un risque à lisser.
- **Ouvrir côté lecteur, pas côté chantier.** La première ligne part du problème que le lecteur cherche à résoudre, pas d'un résumé de ce qu'on a fait (« Comment on streame chez X — la recette tient en quatre briques »). Une question directe peut faire l'affaire (« Comment streamer les réponses d'un LLM jusqu'au navigateur, en Rails ? »), mais ce n'est pas un gabarit à appliquer systématiquement — sinon ça redevient un hook.
- **Dé-brander par défaut.** « On utilise Rails pour pas mal de nos projets », pas « chez <Client> » : le post s'adresse au lecteur, le nom du projet/client n'apporte rien — sauf s'il est le sujet du post.
- **Ressenti simple, puis limite honnête.** « J'aime beaucoup Rails - c'est simple, c'est très pratique d'itérer rapidement, mais c'est pas très facile de streamer (contrairement à Node) » — une opinion assumée en langage parlé, et la faiblesse de l'outil qu'on aime dite sans détour.
- **Couper les élaborations.** Pas de « détail qui surprend : », pas de paragraphe méta de conclusion (« Ce que j'aime dans ce découpage… ») : l'aparté technique tient dans une parenthèse en fin de bullet, et le post se termine au plus court (« Schéma 👇 »). Une parenthèse = une seule info nouvelle, jamais une reformulation de ce que la phrase dit déjà (coupés le 06/07 : « , jamais à l'aller » après « ne sert qu'au retour » ; « , pas de 𝚜𝚝𝚛𝚎𝚊𝚖: 𝚝𝚛𝚞𝚎 à écrire » après « un bloc suffit à activer le streaming »).
- **Ponctuation parlée.** Tiret simple « - » (pas de cadratin « — »), « c'est pas », deux-points collés (« performant: »), pas de point final obligatoire en fin de paragraphe. C'est la voix, ne pas la « corriger ».
- **« Agentic engineering », pas « vibe-coding ».** Pour désigner le dev assisté par LLM, Nicolas a remplacé « vibe-coding » par « agentic engineering » (révision du 06/07, post WhatWouldClaudeUse).
- **Donner aussi l'atout côté lecteur.** Quand le post observe une tendance marché (les LLM recommandent telle stack → enjeu de distribution pour les vendors), ajouter ce que le lecteur y gagne concrètement — ajout du 06/07 : « Pour un développeur, choisir ces outils c'est un atout considérable : on va plus vite, le modèle est entrainé sur des centaines de repositories qui les implémentent ». L'analyse business seule ne suffit pas.
- **Pas donneur de leçon.** Jamais de morale généralisée en conclusion (« Quand on ajoute une brique à une app Rails, on cherche d'abord le pattern que le framework utilise déjà » — rejeté le 06/07 : « c'est nul »). Le post partage un truc qu'on aime (« j'aime bien ce modèle polymorphique, c'est une abstraction simple et puissante ») et le montre par l'exemple concret ; il ne prescrit pas de règle de conduite au lecteur.
- **Layout simple mais propre, via Unicode** (LinkedIn/X ne rendent pas le markdown — un backtick s'affiche tel quel). Nicolas VEUT des bullets et des fragments de code dans le texte : bullets avec « • » ou de simples « - » (sa révision manuelle du 06/07 utilise « - »), identifiants techniques en monospace Unicode (𝚌𝚑𝚊𝚝.𝚊𝚜𝚔, 𝚊𝚒_𝚖𝚎𝚜𝚜𝚊𝚐𝚎𝚜), intertitres en gras Unicode (𝗟𝗲𝘀 𝘁𝗼𝗼𝗹𝘀) avec parcimonie. Le brouillon Notion garde le vrai markdown ; la conversion Unicode se fait au moment de programmer. Caveat : l'Unicode stylé est mal lu par les lecteurs d'écran et non indexé en recherche — le réserver aux identifiants et intertitres, jamais des phrases entières. Les snippets multi-lignes restent dans l'image jointe.
- **Lien vers le blog qraft.tech dans le corps du post** (jamais l'URL notion.site).
- **Cohérence avec l'article lié** : si le post contredit l'article (verdict, chiffres), corriger l'article aussi — versions FR et EN.
- **X : version courte** (~250 caractères, un lien compte pour 23), même registre, pas un teaser racoleur.
- La voix universelle s'applique : première phrase directe qui combine sujet + ressenti, raconter le cheminement, fin honnête, émoji sémantique rare (😅 auto-dérision).

### GitHub PR descriptions, issues, and comments

- **Use plain URLs**, not markdown links, for permalinks to the same repository. GitHub auto-unfurls same-repo links — markdown format like `[text](url)` creates unwanted code previews. Just paste the URL directly.
- PR descriptions: universal voice + concise summary + test plan checklist.

## How to apply

When drafting any message, produce a draft that already has this voice — don't wait for a correction. Match the medium: terse DMs stay terse, formal external messages get formal treatment (ask first if unsure). Default to this style for: Slack team broadcasts, async status updates, informal team messages, internal Notion updates, professional emails.
