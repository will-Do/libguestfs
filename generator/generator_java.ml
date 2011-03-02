(* libguestfs
 * Copyright (C) 2009-2011 Red Hat Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *)

(* Please read generator/README first. *)

open Printf

open Generator_types
open Generator_utils
open Generator_pr
open Generator_docstrings
open Generator_optgroups
open Generator_actions
open Generator_structs
open Generator_c

(* Generate Java bindings GuestFS.java file. *)
let rec generate_java_java () =
  generate_header CStyle LGPLv2plus;

  pr "\
package com.redhat.et.libguestfs;

import java.util.HashMap;
import com.redhat.et.libguestfs.LibGuestFSException;
import com.redhat.et.libguestfs.PV;
import com.redhat.et.libguestfs.VG;
import com.redhat.et.libguestfs.LV;
import com.redhat.et.libguestfs.Stat;
import com.redhat.et.libguestfs.StatVFS;
import com.redhat.et.libguestfs.IntBool;
import com.redhat.et.libguestfs.Dirent;

/**
 * The GuestFS object is a libguestfs handle.
 *
 * @author rjones
 */
public class GuestFS {
  // Load the native code.
  static {
    System.loadLibrary (\"guestfs_jni\");
  }

  /**
   * The native guestfs_h pointer.
   */
  long g;

  /**
   * Create a libguestfs handle.
   *
   * @throws LibGuestFSException
   */
  public GuestFS () throws LibGuestFSException
  {
    g = _create ();
  }
  private native long _create () throws LibGuestFSException;

  /**
   * Close a libguestfs handle.
   *
   * You can also leave handles to be collected by the garbage
   * collector, but this method ensures that the resources used
   * by the handle are freed up immediately.  If you call any
   * other methods after closing the handle, you will get an
   * exception.
   *
   * @throws LibGuestFSException
   */
  public void close () throws LibGuestFSException
  {
    if (g != 0)
      _close (g);
    g = 0;
  }
  private native void _close (long g) throws LibGuestFSException;

  public void finalize () throws LibGuestFSException
  {
    close ();
  }

";

  List.iter (
    fun (name, (ret, args, optargs as style), _, flags, _, shortdesc, longdesc) ->
      if not (List.mem NotInDocs flags); then (
        let doc = replace_str longdesc "C<guestfs_" "C<g." in
        let doc =
          if optargs <> [] then
            doc ^ "\n\nOptional arguments are supplied in the final Map<String,Object> parameter, which is a hash of the argument name to its value (cast to Object).  Pass an empty Map for no optional arguments."
          else doc in
        let doc =
          if List.mem ProtocolLimitWarning flags then
            doc ^ "\n\n" ^ protocol_limit_warning
          else doc in
        let doc =
          if List.mem DangerWillRobinson flags then
            doc ^ "\n\n" ^ danger_will_robinson
          else doc in
        let doc =
          match deprecation_notice flags with
          | None -> doc
          | Some txt -> doc ^ "\n\n" ^ txt in
        let doc = pod2text ~width:60 name doc in
        let doc = List.map (		(* RHBZ#501883 *)
          function
          | "" -> "<p>"
          | nonempty -> nonempty
        ) doc in
        let doc = String.concat "\n   * " doc in

        pr "  /**\n";
        pr "   * %s\n" shortdesc;
        pr "   * <p>\n";
        pr "   * %s\n" doc;
        pr "   * @throws LibGuestFSException\n";
        pr "   */\n";
      );
      pr "  ";
      generate_java_prototype ~public:true ~semicolon:false name style;
      pr "\n";
      pr "  {\n";
      pr "    if (g == 0)\n";
      pr "      throw new LibGuestFSException (\"%s: handle is closed\");\n"
        name;
      pr "    ";
      if ret <> RErr then pr "return ";
      pr "_%s " name;
      generate_java_call_args ~handle:"g" style;
      pr ";\n";
      pr "  }\n";
      pr "  ";
      generate_java_prototype ~privat:true ~native:true name style;
      pr "\n";
      pr "\n";
  ) all_functions;

  pr "}\n"

(* Generate Java call arguments, eg "(handle, foo, bar)" *)
and generate_java_call_args ~handle (_, args, optargs) =
  pr "(%s" handle;
  List.iter (fun arg -> pr ", %s" (name_of_argt arg)) args;
  if optargs <> [] then pr ", optargs";
  pr ")"

and generate_java_prototype ?(public=false) ?(privat=false) ?(native=false)
    ?(semicolon=true) name (ret, args, optargs) =
  if privat then pr "private ";
  if public then pr "public ";
  if native then pr "native ";

  (* return type *)
  (match ret with
   | RErr -> pr "void ";
   | RInt _ -> pr "int ";
   | RInt64 _ -> pr "long ";
   | RBool _ -> pr "boolean ";
   | RConstString _ | RConstOptString _ | RString _
   | RBufferOut _ -> pr "String ";
   | RStringList _ -> pr "String[] ";
   | RStruct (_, typ) ->
       let name = java_name_of_struct typ in
       pr "%s " name;
   | RStructList (_, typ) ->
       let name = java_name_of_struct typ in
       pr "%s[] " name;
   | RHashtable _ -> pr "HashMap<String,String> ";
  );

  if native then pr "_%s " name else pr "%s " name;
  pr "(";
  let needs_comma = ref false in
  if native then (
    pr "long g";
    needs_comma := true
  );

  (* args *)
  List.iter (
    fun arg ->
      if !needs_comma then pr ", ";
      needs_comma := true;

      match arg with
      | Pathname n
      | Device n | Dev_or_Path n
      | String n
      | OptString n
      | FileIn n
      | FileOut n
      | Key n ->
          pr "String %s" n
      | BufferIn n ->
          pr "byte[] %s" n
      | StringList n | DeviceList n ->
          pr "String[] %s" n
      | Bool n ->
          pr "boolean %s" n
      | Int n ->
          pr "int %s" n
      | Int64 n | Pointer (_, n) ->
          pr "long %s" n
  ) args;

  if optargs <> [] then (
    if !needs_comma then pr ", ";
    needs_comma := true;
    pr "HashMap optargs"
  );

  pr ")\n";
  pr "    throws LibGuestFSException";
  if semicolon then pr ";"

and generate_java_struct jtyp cols () =
  generate_header CStyle LGPLv2plus;

  pr "\
package com.redhat.et.libguestfs;

/**
 * Libguestfs %s structure.
 *
 * @author rjones
 * @see GuestFS
 */
public class %s {
" jtyp jtyp;

  List.iter (
    function
    | name, FString
    | name, FUUID
    | name, FBuffer -> pr "  public String %s;\n" name
    | name, (FBytes|FUInt64|FInt64) -> pr "  public long %s;\n" name
    | name, (FUInt32|FInt32) -> pr "  public int %s;\n" name
    | name, FChar -> pr "  public char %s;\n" name
    | name, FOptPercent ->
        pr "  /* The next field is [0..100] or -1 meaning 'not present': */\n";
        pr "  public float %s;\n" name
  ) cols;

  pr "}\n"

and generate_java_c () =
  generate_header CStyle LGPLv2plus;

  pr "\
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include \"com_redhat_et_libguestfs_GuestFS.h\"
#include \"guestfs.h\"

/* Note that this function returns.  The exception is not thrown
 * until after the wrapper function returns.
 */
static void
throw_exception (JNIEnv *env, const char *msg)
{
  jclass cl;
  cl = (*env)->FindClass (env,
                          \"com/redhat/et/libguestfs/LibGuestFSException\");
  (*env)->ThrowNew (env, cl, msg);
}

JNIEXPORT jlong JNICALL
Java_com_redhat_et_libguestfs_GuestFS__1create
  (JNIEnv *env, jobject obj)
{
  guestfs_h *g;

  g = guestfs_create ();
  if (g == NULL) {
    throw_exception (env, \"GuestFS.create: failed to allocate handle\");
    return 0;
  }
  guestfs_set_error_handler (g, NULL, NULL);
  return (jlong) (long) g;
}

JNIEXPORT void JNICALL
Java_com_redhat_et_libguestfs_GuestFS__1close
  (JNIEnv *env, jobject obj, jlong jg)
{
  guestfs_h *g = (guestfs_h *) (long) jg;
  guestfs_close (g);
}

";

  List.iter (
    fun (name, (ret, args, optargs as style), _, _, _, _, _) ->
      pr "JNIEXPORT ";
      (match ret with
       | RErr -> pr "void ";
       | RInt _ -> pr "jint ";
       | RInt64 _ -> pr "jlong ";
       | RBool _ -> pr "jboolean ";
       | RConstString _ | RConstOptString _ | RString _
       | RBufferOut _ -> pr "jstring ";
       | RStruct _ | RHashtable _ ->
           pr "jobject ";
       | RStringList _ | RStructList _ ->
           pr "jobjectArray ";
      );
      pr "JNICALL\n";
      pr "Java_com_redhat_et_libguestfs_GuestFS_";
      pr "%s" (replace_str ("_" ^ name) "_" "_1");
      pr "\n";
      pr "  (JNIEnv *env, jobject obj, jlong jg";
      List.iter (
        function
        | Pathname n
        | Device n | Dev_or_Path n
        | String n
        | OptString n
        | FileIn n
        | FileOut n
        | Key n ->
            pr ", jstring j%s" n
        | BufferIn n ->
            pr ", jbyteArray j%s" n
        | StringList n | DeviceList n ->
            pr ", jobjectArray j%s" n
        | Bool n ->
            pr ", jboolean j%s" n
        | Int n ->
            pr ", jint j%s" n
        | Int64 n | Pointer (_, n) ->
            pr ", jlong j%s" n
      ) args;
      if optargs <> [] then
        pr ", jobject joptargs";
      pr ")\n";
      pr "{\n";
      pr "  guestfs_h *g = (guestfs_h *) (long) jg;\n";
      let error_code, no_ret =
        match ret with
        | RErr -> pr "  int r;\n"; "-1", ""
        | RBool _
        | RInt _ -> pr "  int r;\n"; "-1", "0"
        | RInt64 _ -> pr "  int64_t r;\n"; "-1", "0"
        | RConstString _ -> pr "  const char *r;\n"; "NULL", "NULL"
        | RConstOptString _ -> pr "  const char *r;\n"; "NULL", "NULL"
        | RString _ ->
            pr "  jstring jr;\n";
            pr "  char *r;\n"; "NULL", "NULL"
        | RStringList _ ->
            pr "  jobjectArray jr;\n";
            pr "  int r_len;\n";
            pr "  jclass cl;\n";
            pr "  jstring jstr;\n";
            pr "  char **r;\n"; "NULL", "NULL"
        | RStruct (_, typ) ->
            pr "  jobject jr;\n";
            pr "  jclass cl;\n";
            pr "  jfieldID fl;\n";
            pr "  struct guestfs_%s *r;\n" typ; "NULL", "NULL"
        | RStructList (_, typ) ->
            pr "  jobjectArray jr;\n";
            pr "  jclass cl;\n";
            pr "  jfieldID fl;\n";
            pr "  jobject jfl;\n";
            pr "  struct guestfs_%s_list *r;\n" typ; "NULL", "NULL"
        | RHashtable _ -> pr "  char **r;\n"; "NULL", "NULL"
        | RBufferOut _ ->
            pr "  jstring jr;\n";
            pr "  char *r;\n";
            pr "  size_t size;\n";
            "NULL", "NULL" in
      List.iter (
        function
        | Pathname n
        | Device n | Dev_or_Path n
        | String n
        | OptString n
        | FileIn n
        | FileOut n
        | Key n ->
            pr "  const char *%s;\n" n
        | BufferIn n ->
            pr "  jbyte *%s;\n" n;
            pr "  size_t %s_size;\n" n
        | StringList n | DeviceList n ->
            pr "  int %s_len;\n" n;
            pr "  const char **%s;\n" n
        | Bool n
        | Int n ->
            pr "  int %s;\n" n
        | Int64 n ->
            pr "  int64_t %s;\n" n
        | Pointer (t, n) ->
            pr "  %s %s;\n" t n
      ) args;

      let needs_i =
        (match ret with
         | RStringList _ | RStructList _ -> true
         | RErr | RBool _ | RInt _ | RInt64 _ | RConstString _
         | RConstOptString _
         | RString _ | RBufferOut _ | RStruct _ | RHashtable _ -> false) ||
          List.exists (function
                       | StringList _ -> true
                       | DeviceList _ -> true
                       | _ -> false) args in
      if needs_i then
        pr "  size_t i;\n";

      pr "\n";

      (* Get the parameters. *)
      List.iter (
        function
        | Pathname n
        | Device n | Dev_or_Path n
        | String n
        | FileIn n
        | FileOut n
        | Key n ->
            pr "  %s = (*env)->GetStringUTFChars (env, j%s, NULL);\n" n n
        | OptString n ->
            (* This is completely undocumented, but Java null becomes
             * a NULL parameter.
             *)
            pr "  %s = j%s ? (*env)->GetStringUTFChars (env, j%s, NULL) : NULL;\n" n n n
        | BufferIn n ->
            pr "  %s = (*env)->GetByteArrayElements (env, j%s, NULL);\n" n n;
            pr "  %s_size = (*env)->GetArrayLength (env, j%s);\n" n n
        | StringList n | DeviceList n ->
            pr "  %s_len = (*env)->GetArrayLength (env, j%s);\n" n n;
            pr "  %s = guestfs_safe_malloc (g, sizeof (char *) * (%s_len+1));\n" n n;
            pr "  for (i = 0; i < %s_len; ++i) {\n" n;
            pr "    jobject o = (*env)->GetObjectArrayElement (env, j%s, i);\n"
              n;
            pr "    %s[i] = (*env)->GetStringUTFChars (env, o, NULL);\n" n;
            pr "  }\n";
            pr "  %s[%s_len] = NULL;\n" n n;
        | Bool n
        | Int n
        | Int64 n ->
            pr "  %s = j%s;\n" n n
        | Pointer (t, n) ->
            pr "  %s = (%s) j%s;\n" n t n
      ) args;

      if optargs <> [] then (
        (* XXX *)
        pr "  throw_exception (env, \"%s: internal error: please let us know how to read a Java HashMap parameter from JNI bindings!\");\n" name;
        pr "  return NULL;\n";
        pr "  /*\n";
      );

      (* Make the call. *)
      if optargs = [] then
        pr "  r = guestfs_%s " name
      else
        pr "  r = guestfs_%s_argv " name;
      generate_c_call_args ~handle:"g" style;
      pr ";\n";

      (* Release the parameters. *)
      List.iter (
        function
        | Pathname n
        | Device n | Dev_or_Path n
        | String n
        | FileIn n
        | FileOut n
        | Key n ->
            pr "  (*env)->ReleaseStringUTFChars (env, j%s, %s);\n" n n
        | OptString n ->
            pr "  if (j%s)\n" n;
            pr "    (*env)->ReleaseStringUTFChars (env, j%s, %s);\n" n n
        | BufferIn n ->
            pr "  (*env)->ReleaseByteArrayElements (env, j%s, %s, 0);\n" n n
        | StringList n | DeviceList n ->
            pr "  for (i = 0; i < %s_len; ++i) {\n" n;
            pr "    jobject o = (*env)->GetObjectArrayElement (env, j%s, i);\n"
              n;
            pr "    (*env)->ReleaseStringUTFChars (env, o, %s[i]);\n" n;
            pr "  }\n";
            pr "  free (%s);\n" n
        | Bool _
        | Int _
        | Int64 _
        | Pointer _ -> ()
      ) args;

      (* Check for errors. *)
      pr "  if (r == %s) {\n" error_code;
      pr "    throw_exception (env, guestfs_last_error (g));\n";
      pr "    return %s;\n" no_ret;
      pr "  }\n";

      (* Return value. *)
      (match ret with
       | RErr -> ()
       | RInt _ -> pr "  return (jint) r;\n"
       | RBool _ -> pr "  return (jboolean) r;\n"
       | RInt64 _ -> pr "  return (jlong) r;\n"
       | RConstString _ -> pr "  return (*env)->NewStringUTF (env, r);\n"
       | RConstOptString _ ->
           pr "  return (*env)->NewStringUTF (env, r); /* XXX r NULL? */\n"
       | RString _ ->
           pr "  jr = (*env)->NewStringUTF (env, r);\n";
           pr "  free (r);\n";
           pr "  return jr;\n"
       | RStringList _ ->
           pr "  for (r_len = 0; r[r_len] != NULL; ++r_len) ;\n";
           pr "  cl = (*env)->FindClass (env, \"java/lang/String\");\n";
           pr "  jstr = (*env)->NewStringUTF (env, \"\");\n";
           pr "  jr = (*env)->NewObjectArray (env, r_len, cl, jstr);\n";
           pr "  for (i = 0; i < r_len; ++i) {\n";
           pr "    jstr = (*env)->NewStringUTF (env, r[i]);\n";
           pr "    (*env)->SetObjectArrayElement (env, jr, i, jstr);\n";
           pr "    free (r[i]);\n";
           pr "  }\n";
           pr "  free (r);\n";
           pr "  return jr;\n"
       | RStruct (_, typ) ->
           let jtyp = java_name_of_struct typ in
           let cols = cols_of_struct typ in
           generate_java_struct_return typ jtyp cols
       | RStructList (_, typ) ->
           let jtyp = java_name_of_struct typ in
           let cols = cols_of_struct typ in
           generate_java_struct_list_return typ jtyp cols
       | RHashtable _ ->
           (* XXX *)
           pr "  throw_exception (env, \"%s: internal error: please let us know how to make a Java HashMap from JNI bindings!\");\n" name;
           pr "  return NULL;\n"
       | RBufferOut _ ->
           pr "  jr = (*env)->NewStringUTF (env, r); /* XXX size */\n";
           pr "  free (r);\n";
           pr "  return jr;\n"
      );

      if optargs <> [] then
        pr "  */\n";

      pr "}\n";
      pr "\n"
  ) all_functions

and generate_java_struct_return typ jtyp cols =
  pr "  cl = (*env)->FindClass (env, \"com/redhat/et/libguestfs/%s\");\n" jtyp;
  pr "  jr = (*env)->AllocObject (env, cl);\n";
  List.iter (
    function
    | name, FString ->
        pr "  fl = (*env)->GetFieldID (env, cl, \"%s\", \"Ljava/lang/String;\");\n" name;
        pr "  (*env)->SetObjectField (env, jr, fl, (*env)->NewStringUTF (env, r->%s));\n" name;
    | name, FUUID ->
        pr "  {\n";
        pr "    char s[33];\n";
        pr "    memcpy (s, r->%s, 32);\n" name;
        pr "    s[32] = 0;\n";
        pr "    fl = (*env)->GetFieldID (env, cl, \"%s\", \"Ljava/lang/String;\");\n" name;
        pr "    (*env)->SetObjectField (env, jr, fl, (*env)->NewStringUTF (env, s));\n";
        pr "  }\n";
    | name, FBuffer ->
        pr "  {\n";
        pr "    int len = r->%s_len;\n" name;
        pr "    char s[len+1];\n";
        pr "    memcpy (s, r->%s, len);\n" name;
        pr "    s[len] = 0;\n";
        pr "    fl = (*env)->GetFieldID (env, cl, \"%s\", \"Ljava/lang/String;\");\n" name;
        pr "    (*env)->SetObjectField (env, jr, fl, (*env)->NewStringUTF (env, s));\n";
        pr "  }\n";
    | name, (FBytes|FUInt64|FInt64) ->
        pr "  fl = (*env)->GetFieldID (env, cl, \"%s\", \"J\");\n" name;
        pr "  (*env)->SetLongField (env, jr, fl, r->%s);\n" name;
    | name, (FUInt32|FInt32) ->
        pr "  fl = (*env)->GetFieldID (env, cl, \"%s\", \"I\");\n" name;
        pr "  (*env)->SetLongField (env, jr, fl, r->%s);\n" name;
    | name, FOptPercent ->
        pr "  fl = (*env)->GetFieldID (env, cl, \"%s\", \"F\");\n" name;
        pr "  (*env)->SetFloatField (env, jr, fl, r->%s);\n" name;
    | name, FChar ->
        pr "  fl = (*env)->GetFieldID (env, cl, \"%s\", \"C\");\n" name;
        pr "  (*env)->SetLongField (env, jr, fl, r->%s);\n" name;
  ) cols;
  pr "  free (r);\n";
  pr "  return jr;\n"

and generate_java_struct_list_return typ jtyp cols =
  pr "  cl = (*env)->FindClass (env, \"com/redhat/et/libguestfs/%s\");\n" jtyp;
  pr "  jr = (*env)->NewObjectArray (env, r->len, cl, NULL);\n";
  pr "  for (i = 0; i < r->len; ++i) {\n";
  pr "    jfl = (*env)->AllocObject (env, cl);\n";
  List.iter (
    function
    | name, FString ->
        pr "    fl = (*env)->GetFieldID (env, cl, \"%s\", \"Ljava/lang/String;\");\n" name;
        pr "    (*env)->SetObjectField (env, jfl, fl, (*env)->NewStringUTF (env, r->val[i].%s));\n" name;
    | name, FUUID ->
        pr "    {\n";
        pr "      char s[33];\n";
        pr "      memcpy (s, r->val[i].%s, 32);\n" name;
        pr "      s[32] = 0;\n";
        pr "      fl = (*env)->GetFieldID (env, cl, \"%s\", \"Ljava/lang/String;\");\n" name;
        pr "      (*env)->SetObjectField (env, jfl, fl, (*env)->NewStringUTF (env, s));\n";
        pr "    }\n";
    | name, FBuffer ->
        pr "    {\n";
        pr "      int len = r->val[i].%s_len;\n" name;
        pr "      char s[len+1];\n";
        pr "      memcpy (s, r->val[i].%s, len);\n" name;
        pr "      s[len] = 0;\n";
        pr "      fl = (*env)->GetFieldID (env, cl, \"%s\", \"Ljava/lang/String;\");\n" name;
        pr "      (*env)->SetObjectField (env, jfl, fl, (*env)->NewStringUTF (env, s));\n";
        pr "    }\n";
    | name, (FBytes|FUInt64|FInt64) ->
        pr "    fl = (*env)->GetFieldID (env, cl, \"%s\", \"J\");\n" name;
        pr "    (*env)->SetLongField (env, jfl, fl, r->val[i].%s);\n" name;
    | name, (FUInt32|FInt32) ->
        pr "    fl = (*env)->GetFieldID (env, cl, \"%s\", \"I\");\n" name;
        pr "    (*env)->SetLongField (env, jfl, fl, r->val[i].%s);\n" name;
    | name, FOptPercent ->
        pr "    fl = (*env)->GetFieldID (env, cl, \"%s\", \"F\");\n" name;
        pr "    (*env)->SetFloatField (env, jfl, fl, r->val[i].%s);\n" name;
    | name, FChar ->
        pr "    fl = (*env)->GetFieldID (env, cl, \"%s\", \"C\");\n" name;
        pr "    (*env)->SetLongField (env, jfl, fl, r->val[i].%s);\n" name;
  ) cols;
  pr "    (*env)->SetObjectArrayElement (env, jfl, i, jfl);\n";
  pr "  }\n";
  pr "  guestfs_free_%s_list (r);\n" typ;
  pr "  return jr;\n"

and generate_java_makefile_inc () =
  generate_header HashStyle GPLv2plus;

  pr "java_built_sources = \\\n";
  List.iter (
    fun (typ, jtyp) ->
        pr "\tcom/redhat/et/libguestfs/%s.java \\\n" jtyp;
  ) java_structs;
  pr "\tcom/redhat/et/libguestfs/GuestFS.java\n"
