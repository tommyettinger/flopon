// Do not edit this file! Generated by Ragel.
// Ragel.exe -G2 -J -o FloponReader.java FloponReader.rl
/*******************************************************************************
 * Copyright 2011 See AUTHORS file.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 ******************************************************************************/

package com.github.tommyettinger.flopon;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import com.badlogic.gdx.utils.*;

import com.badlogic.gdx.files.FileHandle;
import com.github.tommyettinger.flopon.FloponValue.ValueType;
import static com.github.tommyettinger.flopon.NumericBase.FLOPON_SAFE;

/** Lightweight Flopon parser.<br>
 * <br>
 * The default behavior is to parse the Flopon into a DOM containing {@link FloponValue} objects. Extend this class and override
 * methods to perform event driven parsing. When this is done, the parse methods will return null.
 * @author Nathan Sweet */
public class FloponReader {
	public FloponValue parse (String flopon) {
		char[] data = flopon.toCharArray();
		return parse(data, 0, data.length);
	}

	public FloponValue parse (Reader reader) {
		char[] data = new char[1024];
		int offset = 0;
		try {
			while (true) {
				int length = reader.read(data, offset, data.length - offset);
				if (length == -1) break;
				if (length == 0) {
					char[] newData = new char[data.length * 2];
					System.arraycopy(data, 0, newData, 0, data.length);
					data = newData;
				} else
					offset += length;
			}
		} catch (IOException ex) {
			throw new SerializationException("Error reading input.", ex);
		} finally {
			StreamUtils.closeQuietly(reader);
		}
		return parse(data, 0, offset);
	}

	public FloponValue parse (InputStream input) {
		Reader reader;
		try {
			reader = new InputStreamReader(input, "UTF-8");
		} catch (Exception ex) {
			throw new SerializationException("Error reading stream.", ex);
		}
		return parse(reader);
	}

	public FloponValue parse (FileHandle file) {
		Reader reader;
		try {
			reader = file.reader("UTF-8");
		} catch (Exception ex) {
			throw new SerializationException("Error reading file: " + file, ex);
		}
		try {
			return parse(reader);
		} catch (Exception ex) {
			throw new SerializationException("Error parsing file: " + file, ex);
		}
	}

	public FloponValue parse (char[] data, int offset, int length) {
		int cs, p = offset, pe = length, eof = pe, top = 0;
		int[] stack = new int[4];

		int s = 0;
		Array<String> names = new Array(8);
		boolean needsUnescape = false, stringIsName = false, stringIsUnquoted = false;
		RuntimeException parseRuntimeEx = null;

		boolean debug = true;
		if (debug) System.out.println();

		try {
		%%{
			machine flopon;

			prepush {
				if (top == stack.length) {
					int[] newStack = new int[stack.length * 2];
					System.arraycopy(stack, 0, newStack, 0, stack.length);
					stack = newStack;
				}
			}

			action name {
				stringIsName = true;
			}
			action string {
				String value = new String(data, s, p - s);
				if (needsUnescape) value = unescape(value);
				outer:
				if (stringIsName) {
					stringIsName = false;
					if (debug) System.out.println("name: " + value);
					names.add(value);
				} else {
					String name = names.size > 0 ? names.pop() : null;
					if (stringIsUnquoted) {
						if (value.equals("true")) {
							if (debug) System.out.println("boolean: " + name + "=true");
							bool(name, true);
							break outer;
						} else if (value.equals("false")) {
							if (debug) System.out.println("boolean: " + name + "=false");
							bool(name, false);
							break outer;
						} else if (value.equals("null")) {
							string(name, null);
							break outer;
						}
						boolean couldBeDouble = false, couldBeLong = true;
						outer2:
						for (int i = s; i < p; i++) {
							char d = data[i];
							if((d >= '0' && d <= '9') || d == '+' || d == '-') continue;
							else if((d >= 'A' && d <= 'Z') || (d >= 'a' && d <= 'z') || d == '$' || d == '_') {
								couldBeDouble = true;
								couldBeLong = false;
							}
							else {
								couldBeDouble = false;
								couldBeLong = false;
								break outer2;
							}
						}
						if (couldBeDouble) {
							try {
								if (debug) System.out.println("double: " + name + "=" + FLOPON_SAFE.readDoubleEx(value));
								number(name, FLOPON_SAFE.readDoubleEx(value), value);
								break outer;
							} catch (NumberFormatException ignored) {
							}
						} else if (couldBeLong) {
							if (debug) System.out.println("long: " + name + "=" + Long.parseLong(value));
							try {
								number(name, Long.parseLong(value), value);
								break outer;
							} catch (NumberFormatException ignored) {
							}
						}
					}
					if (debug) System.out.println("string: " + name + "=" + value);
					string(name, value);
				}
				stringIsUnquoted = false;
				s = p;
			}
			action startObject {
				String name = names.size > 0 ? names.pop() : null;
				if (debug) System.out.println("startObject: " + name);
				startObject(name);
				fcall object;
			}
			action endObject {
				if (debug) System.out.println("endObject");
				pop();
				fret;
			}
			action startArray {
				String name = names.size > 0 ? names.pop() : null;
				if (debug) System.out.println("startArray: " + name);
				startArray(name);
				fcall array;
			}
			action endArray {
				if (debug) System.out.println("endArray");
				pop();
				fret;
			}
			action comment {
				int start = p - 1;
				if (data[p++] == '/') {
					while (p != eof && data[p] != '\n')
						p++;
					p--;
				} else {
					while (p + 1 < eof && data[p] != '*' || data[p + 1] != '/')
						p++;
					p++;
				}
				if (debug) System.out.println("comment " + new String(data, start, p - start));
			}
			action unquotedChars {
				if (debug) System.out.println("unquotedChars");
				s = p;
				needsUnescape = false;
				stringIsUnquoted = true;
				if (stringIsName) {
					outer:
					while (true) {
						switch (data[p]) {
						case '\\':
							needsUnescape = true;
							break;
						case '/':
							if (p + 1 == eof) break;
							char c = data[p + 1];
							if (c == '/' || c == '*') break outer;
							break;
						case ':':
						case '\r':
						case '\n':
							break outer;
						}
						if (debug) System.out.println("unquotedChar (name): '" + data[p] + "'");
						p++;
						if (p == eof) break;
					}
				} else {
					outer:
					while (true) {
						switch (data[p]) {
						case '\\':
							needsUnescape = true;
							break;
						case '/':
							if (p + 1 == eof) break;
							char c = data[p + 1];
							if (c == '/' || c == '*') break outer;
							break;
						case '}':
						case ']':
						case ',':
						case '\r':
						case '\n':
							break outer;
						}
						if (debug) System.out.println("unquotedChar (value): '" + data[p] + "'");
						p++;
						if (p == eof) break;
					}
				}
				p--;
				while (Character.isSpace(data[p]))
					p--;
			}
			action quotedChars {
				if (debug) System.out.println("quotedChars");
				s = ++p;
				needsUnescape = false;
				outer:
				while (true) {
					switch (data[p]) {
					case '\\':
						needsUnescape = true;
						p++;
						break;
					case '"':
						break outer;
					}
					// if (debug) System.out.println("quotedChar: '" + data[p] + "'");
					p++;
					if (p == eof) break;
				}
				p--;
			}

			comment = ('//' | '/*') @comment;
			ws = [\r\n\t ] | comment;
			ws2 = [\t ] | comment;
			comma = ',' | ([\r\n] ws* ','?);
			quotedString = '"' @quotedChars %string '"';
			nameString = quotedString | ^[":,}/\r\n\t ] >unquotedChars %string;
			valueString = quotedString | ^[":,{[\]/\r\n\t ] >unquotedChars %string;
			value = '{' @startObject | '[' @startArray | valueString;
			nameValue = nameString >name ws* ':' ws* value;
			object := ws* nameValue? ws2* <: (comma ws* nameValue ws2*)** :>> (','? ws* '}' @endObject);
			array := ws* value? ws2* <: (comma ws* value ws2*)** :>> (','? ws* ']' @endArray);
			main := ws* value ws*;

			write init;
			write exec;
		}%%
		} catch (RuntimeException ex) {
			parseRuntimeEx = ex;
		}

		FloponValue root = this.root;
		this.root = null;
		current = null;
		lastChild.clear();

		if (p < pe) {
			int lineNumber = 1;
			for (int i = 0; i < p; i++)
				if (data[i] == '\n') lineNumber++;
			int start = Math.max(0, p - 32);
			throw new SerializationException("Error parsing JSON on line " + lineNumber + " near: "
				+ new String(data, start, p - start) + "*ERROR*" + new String(data, p, Math.min(64, pe - p)), parseRuntimeEx);
		}
		if (elements.size != 0) {
			FloponValue element = elements.peek();
			elements.clear();
			if (element != null && element.isObject())
				throw new SerializationException("Error parsing JSON, unmatched brace.");
			else
				throw new SerializationException("Error parsing JSON, unmatched bracket.");
		}
		if (parseRuntimeEx != null) throw new SerializationException("Error parsing JSON: " + new String(data), parseRuntimeEx);
		return root;
	}

	%% write data;

	private final Array<FloponValue> elements = new Array(8);
	private final Array<FloponValue> lastChild = new Array(8);
	private FloponValue root, current;

	/** @param name May be null. */
	private void addChild (@Null String name, FloponValue child) {
		child.setName(name);
		if (current == null) {
			current = child;
			root = child;
		} else if (current.isArray() || current.isObject()) {
			child.parent = current;
			if (current.size == 0)
				current.child = child;
			else {
				FloponValue last = lastChild.pop();
				last.next = child;
				child.prev = last;
			}
			lastChild.add(child);
			current.size++;
		} else
			root = current;
	}

	/** @param name May be null. */
	protected void startObject (@Null String name) {
		FloponValue value = new FloponValue(ValueType.object);
		if (current != null) addChild(name, value);
		elements.add(value);
		current = value;
	}

	/** @param name May be null. */
	protected void startArray (@Null String name) {
		FloponValue value = new FloponValue(ValueType.array);
		if (current != null) addChild(name, value);
		elements.add(value);
		current = value;
	}

	protected void pop () {
		root = elements.pop();
		if (current.size > 0) lastChild.pop();
		current = elements.size > 0 ? elements.peek() : null;
	}

	protected void string (String name, String value) {
		addChild(name, new FloponValue(value));
	}

	protected void number (String name, double value, String stringValue) {
		addChild(name, new FloponValue(value, stringValue));
	}

	protected void number (String name, long value, String stringValue) {
		addChild(name, new FloponValue(value, stringValue));
	}

	protected void bool (String name, boolean value) {
		addChild(name, new FloponValue(value));
	}

	private String unescape (String value) {
		int length = value.length();
		StringBuilder buffer = new StringBuilder(length + 16);
		for (int i = 0; i < length;) {
			char c = value.charAt(i++);
			if (c != '\\') {
				buffer.append(c);
				continue;
			}
			if (i == length) break;
			c = value.charAt(i++);
			if (c == 'u') {
				buffer.append(Character.toChars(Integer.parseInt(value.substring(i, i + 4), 16)));
				i += 4;
				continue;
			}
			switch (c) {
			case '"':
			case '\\':
			case '/':
				break;
			case 'b':
				c = '\b';
				break;
			case 'f':
				c = '\f';
				break;
			case 'n':
				c = '\n';
				break;
			case 'r':
				c = '\r';
				break;
			case 't':
				c = '\t';
				break;
			default:
				throw new SerializationException("Illegal escaped character: \\" + c);
			}
			buffer.append(c);
		}
		return buffer.toString();
	}
}
