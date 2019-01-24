# Copyright (C) 2012-2016  CEA/DEN, EDF R&D
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
#
# See http://www.salome-platform.org/ or email : webmaster.salome@opencascade.com
#

##
## This module is dedicated to the generation of specific SWIG files (".i") containing
## the docstrings built from the C++ doxygen documentation.
##

SET(_DOXY2SWIG ${PROJECT_SOURCE_DIR}/doc/developer/doxygen/doxy2swig/doxy2swig.py)

SET(_SWIG_DOC_SUFFIX "doc_class_")

#
# MEDCoupling classes to include
#
SET(_classes_MEDCoupling
   MEDCoupling_1_1MEDCouplingPointSet
   MEDCoupling_1_1MEDCouplingUMesh
   MEDCoupling_1_1MEDCouplingCMesh
   MEDCoupling_1_1MEDCouplingRemapper
   MEDCoupling_1_1DataArray
   #MEDCoupling_1_1DataArrayInt
   MEDCoupling_1_1DataArrayDouble
    )

#
# MEDLoader classes to include
#
SET(_classes_MEDLoader
    MEDCoupling_1_1MEDFileMeshes
    MEDCoupling_1_1MEDFileMesh
    MEDCoupling_1_1MEDFileUMesh
    MEDCoupling_1_1MEDFileCMesh
    )

##
## Generates the ".i" files from a list of C++ classes.
##
## \param[in] target_doc main target for the stantard doxygen generation
## \param[in] target_swig dummy target encompassing the final build of all SWIG files
## \param[in] cls_list list of classes for which to generate SWIG files
## \param[in] swig_main_file main SWIG file including the other generated SWIG files
## \param[out] swig_files list of generated SWIG files
##
MACRO(MEDCOUPLING_SWIG_DOCSTRING_GENERATE target_doc target_swig cls_list swig_main_file swig_files)
    # List of generated SWIG files (.i) for doc purposes only:
    SET(${swig_files})
    FOREACH(_cls IN LISTS ${cls_list})
      SET(_xml_file "${CMAKE_CURRENT_BINARY_DIR}/../doxygen/doc_ref_dev/xml/class${_cls}.xml")
      SET(_swig_file_base "${_SWIG_DOC_SUFFIX}${_cls}.i")
      SET(_swig_file "${PROJECT_BINARY_DIR}/doc/${_swig_file_base}" )

      # SWIG doc files will always be generated *after* Doxygen is run:
      ### WARNING: ADD_CUSTOM_COMMAND(TARGET xxx POST_BUILD ...) command
      ### must be in exactly the same subdir as the initial target construction command.
      ### That's why this file is included with an INCLUDE() rather than using ADD_SUBDIRECTORY
      # Note: we touch the main .i file to be sure to retrigger swig when the doc in a included
      # class changes.
      ADD_CUSTOM_COMMAND(OUTPUT ${_swig_file}
        COMMAND ${PYTHON_EXECUTABLE} ${_DOXY2SWIG} "-n" ${_xml_file} ${_swig_file}
        COMMAND ${CMAKE_COMMAND} -E touch_nocreate ${swig_main_file}
        DEPENDS ${_xml_file}
        COMMENT "Generating docstring SWIG file (from Doxygen's XML): ${_swig_file_base}"
        VERBATIM
      )
      ADD_CUSTOM_TARGET(${_swig_file_base} DEPENDS ${_swig_file})
      # The doxy2swig script is executed once the doxygen documentation has been generated ...
      ADD_DEPENDENCIES(${_swig_file_base} ${target_doc})
      # ... and the meta target 'swig_ready' (here ${target_swig}) is ready when all .i files
      # have been generated:
      ADD_DEPENDENCIES(${target_swig} ${_swig_file_base})

      LIST(APPEND ${swig_files} ${_swig_file_base})
    ENDFOREACH()
ENDMACRO(MEDCOUPLING_SWIG_DOCSTRING_GENERATE)


##
## Configures the MEDCoupling_doc.i or MEDLoader_doc.i file so that they include
## the list of SWIG files generated by the macro above.
##
## \param[in] target_doc main target for the stantard doxygen generation
## \param[in] target_swig dummy target encompassing the final build of all SWIG files
## \param[in] root_name either 'MEDCoupling' or 'MEDLoader'
##
MACRO(MEDCOUPLING_SWIG_DOCSTRING_CONFIGURE target_doc target_swig root_name)
    SET(_all_swig_docs)
    SET(_swig_include_set)
    SET(_in_file doxy2swig/${root_name}_doc.i.in)
    SET(_out_file ${PROJECT_BINARY_DIR}/doc/${root_name}_doc.i)
    MEDCOUPLING_SWIG_DOCSTRING_GENERATE(${target_doc} ${target_swig} _classes_${root_name} ${_out_file} _all_swig_docs)
    FOREACH(f IN LISTS _all_swig_docs)
        SET(_swig_include_set "${_swig_include_set}\n%include \"${f}\"")
    ENDFOREACH()
    CONFIGURE_FILE(${_in_file} ${_out_file} @ONLY)
ENDMACRO(MEDCOUPLING_SWIG_DOCSTRING_CONFIGURE)
