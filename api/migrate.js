import {readFile} from 'node:fs/promises';
import {db} from './db.js';
try {await db.query(await readFile(new URL('./schema.sql',import.meta.url),'utf8'));} finally {await db.end();}
