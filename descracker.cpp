#include "descracker.h"
#include <cstring>
#include <cstdio>

const char alphabet[] = { 0, 'a', 'b', 'c'};

void word_for(int num, block_t* word, int alphabets)
{
	int sub = 1;
	int exp = 1;

	alphabets--;
	((char*)word)[7] = alphabet[((num - sub) >= 0)*(((num - sub) / exp) % alphabets + 1)];
	exp *= alphabets;
	sub += exp;
	((char*)word)[6] = alphabet[((num - sub) >= 0)*(((num - sub) / exp) % alphabets + 1)];
	exp *= alphabets;
	sub += exp;
	((char*)word)[5] = alphabet[((num - sub) >= 0)*(((num - sub) / exp) % alphabets + 1)];
	exp *= alphabets;
	sub += exp;
	((char*)word)[4] = alphabet[((num - sub) >= 0)*(((num - sub) / exp) % alphabets + 1)];
	exp *= alphabets;
	sub += exp;
	((char*)word)[3] = alphabet[((num - sub) >= 0)*(((num - sub) / exp) % alphabets + 1)];
	exp *= alphabets;
	sub += exp;
	((char*)word)[2] = alphabet[((num - sub) >= 0)*(((num - sub) / exp) % alphabets + 1)];
	exp *= alphabets;
	sub += exp;
	((char*)word)[1] = alphabet[((num - sub) >= 0)*(((num - sub) / exp) % alphabets + 1)];
	exp *= alphabets;
	sub += exp;
	((char*)word)[0] = alphabet[((num - sub) >= 0)*(((num - sub) / exp) % alphabets + 1)];
}

void fast_text_to_block(const char* text, block_t* block)
{
	*block = (0x00ffffffffffffff & *block) | (((block_t)(text[0])) << 56);
	*block = (0xff00ffffffffffff & *block) | (((block_t)(text[1])) << 48);
	*block = (0xffff00ffffffffff & *block) | (((block_t)(text[2])) << 40);
	*block = (0xffffff00ffffffff & *block) | (((block_t)(text[3])) << 32);
	*block = (0xffffffff00ffffff & *block) | (((block_t)(text[4])) << 24);
	*block = (0xffffffffff00ffff & *block) | (((block_t)(text[5])) << 16);
	*block = (0xffffffffffff00ff & *block) | (((block_t)(text[6])) << 8);
	*block = (0xffffffffffffff00 & *block) | ((block_t)(text[7]));
}

block_t des_crack(block_t msg)
{
	char mess[9];
	int indkey[8], indmsg[8];
	int wordnum, keynum;
	block_t tmpkey = 0, tmpmsg = 0, encmsg = 0, lastWord;
	int alphabets = sizeof(alphabet);
	
	memset(mess, 0, 9);
	memset(mess, alphabet[alphabets - 1], 8);
	text_to_block(mess, &lastWord);

	keynum = 0;
	while (tmpkey != lastWord)
	{
		memset(mess, 0, 8);
		word_for(keynum++, &tmpkey, alphabets);
		printf("Checking key: %016llx\n", tmpkey);
		
		tmpmsg = 0;
		wordnum = 0;
		while (tmpmsg != lastWord)
		{
			word_for(wordnum++, &tmpmsg, alphabets);

			encmsg = tmpmsg;
			des_encrypt(&encmsg, 1, tmpkey);
			if (encmsg == msg)
				return tmpkey;
		}
	}
	return 0;
}