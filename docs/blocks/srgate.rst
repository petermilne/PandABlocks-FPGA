SRGATE - Set Reset Gate [x4]
============================
An SRGATE block produces either a high (SET) or low (RESET) output. It has
configurable inputs and an option to force its output independently.Both Set
and Reset inputs can be selected from system bus, and the active-edge of its
inputs is configurable


Parameters
----------
=============== === ======= ===================================================
Name            Dir Type    Description
=============== === ======= ===================================================
SET_EDGE        R/W Enum    | 0 - Sets the output to 1 on rising edge
                            | 1 - Sets the output to 1 on falling edge
RESET_EDGE      R/W Enum    | 0 - Resets the output on rising edge
                            | 1 - Resets the outputon falling edge
FORCE_RESET     W   Action  Reset output to 0
FORCE_SET       W   Action  Set output to 0
SET             In  Bit     A falling/rising edge sets the output to 1
RESET           In  Bit     A falling/rising edge resets the output to 0
OUT             Out Bit     Output value
=============== === ======= ===================================================

Normal conditions
-----------------

The normal behaviour is to set the output OUT on the configured edge of the
SET or RESET input.

.. sequence_plot::
   :block: srgate
   :title: Set on rising Edge

.. sequence_plot::
   :block: srgate
   :title: Set on falling Edge

.. sequence_plot::
   :block: srgate
   :title: Reset on rising Edge

.. sequence_plot::
   :block: srgate
   :title: Reset on falling Edge

Active edge configure conditions
--------------------------------
if the active edge is 'rising' then reset to 'falling' at the same time as a
rising edge on the SET input, the block will ignore the rising edge and set
the output OUT on the falling edge of the SET input.

.. sequence_plot::
   :block: srgate
   :title: Rising SET with SET_EDGE reconfigure

If the active edge changes to 'falling'  at the same time as a falling edge
on the SET input, the output OUT will be set following this.

.. sequence_plot::
   :block: srgate
   :title: Falling SET wtih SET_EDGE reconfigure

.. sequence_plot::
   :block: srgate
   :title: Falling RST with with reset edge reconfigure

Set-reset conditions
--------------------

When determining the output if two values are set simultaneously, FORCE_SET and
FORCE_RESET registers take priority over the input bus, and reset takes priority
over set.

.. sequence_plot::
   :block: srgate
   :title: Set-reset conditions

